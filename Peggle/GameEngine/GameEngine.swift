import Combine
import CoreGraphics
import Foundation

final class GameEngine {
    private let entityManager = EntityManager()
    private let physicsWorld = PhysicsWorld()

    private let entityFactory: EntityFactory
    private let systems: [System]

    private var ballEntity: Entity?
    private var ballTimer: Timer?
    private var bucketEntity: Entity!

    private var componentsCancellable: AnyCancellable?
    private var collisionCancellable: AnyCancellable?

    init(elements: [Element]) {
        entityFactory = EntityFactory(entityManager: entityManager)
        systems = [
            PhysicsSystem(entityManager: entityManager),
            PowerSystem(entityManager: entityManager),
            AimSystem(entityManager: entityManager),
            OscillateSystem(entityManager: entityManager),
            LightSystem(entityManager: entityManager),
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
            }

            // Ball entered bucket
            if let ball = self?.ballEntity,
               let ballBody = self?.entityManager.getComponent(PhysicsComponent.self, for: ball)?.physicsBody,
               let bucket = self?.bucketEntity,
               let bucketBody = self?.entityManager.getComponent(PhysicsComponent.self, for: bucket)?.physicsBody,
               [ballBody, bucketBody].allSatisfy({ $0 === bodyA || $0 === bodyB }) {
                ballBody.position.y = 1.5
                print("Ball entered bucket")
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
            entityManager.addComponent(PowerComponent(power: .spaceBlast), to: pegEntity)
        }
    }

    func getRenderComponents() -> [RenderComponent] {
        entityManager.getComponents(RenderComponent.self)
    }

    func onDrag(position: CGPoint) {
        guard ballEntity == nil else {
            return
        }

        let entities = entityManager.getEntities(for: AimComponent.self)

        for entity in entities {
            guard let aimComponent = entityManager.getComponent(AimComponent.self, for: entity) else {
                continue
            }

            aimComponent.target = position
        }
    }

    func onDragEnd(position: CGPoint) {
        guard ballEntity == nil else {
            return
        }

        let entities = entityManager.getEntities(for: AimComponent.self)

        for entity in entities {
            guard let aimComponent = entityManager.getComponent(AimComponent.self, for: entity) else {
                continue
            }

            aimComponent.target = nil

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
            ballEntity = entityFactory.createBall(position: aimComponent.position,
                                                  velocity: (actualPosition - aimComponent.position)
                                                    .normalized())
        }
    }

    func removePegs() {
        guard let ball = ballEntity,
              let physicsBody = entityManager.getComponent(PhysicsComponent.self, for: ball)?.physicsBody else {
            return
        }

        removePegsWhenBallStuck(ball: ball, physicsBody: physicsBody)
        removePegsWhenBallExits(ball: ball, physicsBody: physicsBody)
    }

    func removePegsWhenBallStuck(ball: Entity, physicsBody: PhysicsBody) {
        // Cancel timer if it turns out ball isn't actually resting
        guard physicsBody.isResting == true else {
            ballTimer?.invalidate()
            ballTimer = nil

            return
        }

        // Only start new timer if previous timer invalidated or expired
        if ballTimer == nil || !(ballTimer?.isValid ?? true) {
            ballTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(physicsWorld.speed),
                                             repeats: false) { [self] _ in
                let entities = entityManager.getEntities(for: LightComponent.self)
                var minDistance = CGFloat.infinity
                var minEntity: Entity?

                for entity in entities {
                    guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                          let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                          lightComponent.isLit == true else {
                        continue
                    }

                    let distance = physicsBody.position.distance(to: physicsComponent.physicsBody.position)

                    if distance < minDistance {
                        minDistance = distance
                        minEntity = entity
                    }
                }

                if let entity = minEntity {
                    entityManager.removeEntity(entity)
                }
            }
        }
    }

    func removePegsWhenBallExits(ball: Entity, physicsBody: PhysicsBody) {
        guard physicsBody.position.y >= 1.5 else {
            return
        }

        let entities = entityManager.getEntities(for: LightComponent.self)

        for entity in entities {
            guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                  lightComponent.isLit == true else {
                continue
            }

            entityManager.removeEntity(entity)
        }

        entityManager.removeEntity(ball)
        ballEntity = nil
    }

    func update(deltaTime seconds: CGFloat) {
        physicsWorld.update(deltaTime: seconds)

        for system in systems {
            system.update(deltaTime: seconds)
        }

        removePegs()
    }
}
