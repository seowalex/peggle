import Combine
import CoreGraphics
import Foundation

final class GameEngine {
    private let entityManager = EntityManager()
    private let physicsWorld = PhysicsWorld()

    private let entityFactory: EntityFactory
    private let systems: [System]

    private var bucketEntity: Entity!

    private var componentsCancellable: AnyCancellable?
    private var collisionCancellable: AnyCancellable?

    init(elements: [Element]) {
        entityFactory = EntityFactory(entityManager: entityManager)
        systems = [
            PhysicsSystem(entityManager: entityManager),
            PowerSystem(entityManager: entityManager),
            AimSystem(entityManager: entityManager),
            TrajectorySystem(entityManager: entityManager),
            OscillateSystem(entityManager: entityManager),
            LightSystem(entityManager: entityManager),
            ClearSystem(entityManager: entityManager),
            RenderSystem(entityManager: entityManager)
        ]

        createEntities(elements: elements)

        componentsCancellable = entityManager.$components.sink { [weak self] _ in
            guard let bodies = self?.entityManager.getComponents(PhysicsComponent.self).map({ $0.physicsBody }) else {
                return
            }

            self?.physicsWorld.bodies = bodies
        }

        collisionCancellable = physicsWorld.collisionPublisher.sink { [weak self] bodyA, bodyB in
            guard let entities = self?.entityManager.getEntities(for: PhysicsComponent.self) else {
                return
            }

            for entity in entities {
                // Activate powers
                if let powerComponent = self?.entityManager.getComponent(PowerComponent.self, for: entity),
                   let physicsComponent = self?.entityManager.getComponent(PhysicsComponent.self, for: entity),
                   physicsComponent.physicsBody === bodyA || physicsComponent.physicsBody === bodyB {
                    powerComponent.isActivated = true
                }

                // Light pegs
                if let lightComponent = self?.entityManager.getComponent(LightComponent.self, for: entity),
                   let physicsComponent = self?.entityManager.getComponent(PhysicsComponent.self, for: entity),
                   physicsComponent.physicsBody === bodyA || physicsComponent.physicsBody === bodyB {
                    lightComponent.isLit = true
                }

                // Check for ball entering bucket
                if let clearComponent = self?.entityManager.getComponent(ClearComponent.self, for: entity),
                   let physicsComponent = self?.entityManager.getComponent(PhysicsComponent.self, for: entity),
                   let bucket = self?.bucketEntity,
                   let bucketBody = self?.entityManager.getComponent(PhysicsComponent.self, for: bucket)?.physicsBody,
                   clearComponent.willClear == false
                    && [physicsComponent.physicsBody, bucketBody].allSatisfy({ $0 === bodyA || $0 === bodyB }) {
                    clearComponent.willClear = true
                    print("ball entered bucket")
                }
            }
        }
    }

    func createEntities(elements: [Element]) {
        entityFactory.createWall(position: CGPoint(x: 0.5, y: -0.2), size: CGSize(width: 1, height: 0.4))
        entityFactory.createWall(position: CGPoint(x: -0.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))
        entityFactory.createWall(position: CGPoint(x: 1.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))

        entityFactory.createCannon(position: CGPoint(x: 0.5, y: 0.07))
        bucketEntity = entityFactory.createBucket(position: CGPoint(x: 0.5, y: 1.37),
                                                  startPoint: CGPoint(x: 0.1, y: 1.37),
                                                  endPoint: CGPoint(x: 0.9, y: 1.37),
                                                  frequency: 0.4)

        let greenPegs = elements.compactMap { $0 as? Peg }.filter { $0.color == .blue }.shuffled().prefix(2)

        for element in elements.filter({ element in !greenPegs.contains { $0 === element } }) {
            let position = element.position.applying(CGAffineTransform(translationX: 0, y: 0.3))
            let rotation = element.rotation
            let size = element.size

            if let peg = element as? Peg {
                entityFactory.createPeg(position: position, imageName: peg.imageName, rotation: rotation, size: size)
            } else if element is Block {
                entityFactory.createBlock(position: position, rotation: rotation, size: size)
            }
        }

        for peg in greenPegs {
            let pegEntity = entityFactory.createPeg(position: peg.position.applying(CGAffineTransform(translationX: 0,
                                                                                                      y: 0.3)),
                                                    imageName: "peg-green",
                                                    rotation: peg.rotation,
                                                    size: peg.size)
            entityManager.addComponent(PowerComponent(power: .spookyBall), to: pegEntity)
        }
    }

    func getRenderComponents() -> [RenderComponent] {
        entityManager.getComponents(RenderComponent.self)
    }

    func onDrag(position: CGPoint) {
        guard entityManager.getComponents(ClearComponent.self).isEmpty else {
            return
        }

        let entities = entityManager.getEntities(for: AimComponent.self)

        for entity in entities {
            guard let aimComponent = entityManager.getComponent(AimComponent.self, for: entity),
                  let trajectoryComponent = entityManager.getComponent(TrajectoryComponent.self, for: entity) else {
                continue
            }

            aimComponent.target = position

            // Clamp the firing angle between minAngle and maxAngle
            let normalizedTarget = position.rotate(around: aimComponent.position,
                                                   by: -aimComponent.initialAngle)
            let angle = aimComponent.position.angle(to: normalizedTarget)
            let clampedAngle = min(max(aimComponent.position.angle(to: normalizedTarget),
                                       aimComponent.minAngle),
                                   aimComponent.maxAngle)
            let difference = clampedAngle - angle
            let actualPosition = position.rotate(around: aimComponent.position, by: difference)

            // Have to normalize the velocity so that the speed remains constant no matter
            // how far the tap is from the cannon
            trajectoryComponent.velocity = (actualPosition - aimComponent.position).normalized()
        }
    }

    func onDragEnd(position: CGPoint) {
        guard entityManager.getComponents(ClearComponent.self).isEmpty else {
            return
        }

        let entities = entityManager.getEntities(for: AimComponent.self)

        for entity in entities {
            guard let aimComponent = entityManager.getComponent(AimComponent.self, for: entity),
                  let trajectoryComponent = entityManager.getComponent(TrajectoryComponent.self, for: entity) else {
                continue
            }

            aimComponent.target = nil
            trajectoryComponent.velocity = nil
            trajectoryComponent.points = []

            // Clamp the firing angle between minAngle and maxAngle
            let normalizedTarget = position.rotate(around: aimComponent.position,
                                                   by: -aimComponent.initialAngle)
            let angle = aimComponent.position.angle(to: normalizedTarget)
            let clampedAngle = min(max(aimComponent.position.angle(to: normalizedTarget),
                                       aimComponent.minAngle),
                                   aimComponent.maxAngle)
            let difference = clampedAngle - angle
            let actualPosition = position.rotate(around: aimComponent.position, by: difference)

            // Have to normalize the velocity so that the speed remains constant no matter
            // how far the tap is from the cannon
            entityFactory.createBall(position: aimComponent.position,
                                     velocity: (actualPosition - aimComponent.position).normalized(),
                                     physicsSpeed: physicsWorld.speed)
        }
    }

    func updateTrajectories(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: TrajectoryComponent.self)

        for entity in entities {
            guard let trajectoryComponent = entityManager.getComponent(TrajectoryComponent.self, for: entity),
                  let aimComponent = entityManager.getComponent(AimComponent.self, for: entity),
                  let velocity = trajectoryComponent.velocity else {
                continue
            }

            trajectoryComponent.points = physicsWorld
                .getTrajectoryPoints(body: PhysicsBody(shape: trajectoryComponent.shape,
                                                       size: trajectoryComponent.size,
                                                       position: aimComponent.position,
                                                       velocity: velocity),
                                     deltaTime: seconds,
                                     maxCollisions: trajectoryComponent.maxCollisions)
        }
    }

    func update(deltaTime seconds: CGFloat) {
        physicsWorld.update(deltaTime: seconds)
        updateTrajectories(deltaTime: seconds)

        for system in systems {
            system.update(deltaTime: seconds)
        }
    }
}
