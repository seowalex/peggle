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

    private var componentsCancellable: AnyCancellable?
    private var collisionCancellable: AnyCancellable?

    init(elements: [Element]) {
        entityFactory = EntityFactory(entityManager: entityManager)
        systems = [
            PhysicsSystem(entityManager: entityManager),
            LightSystem(entityManager: entityManager),
            AimSystem(entityManager: entityManager),
            RenderSystem(entityManager: entityManager)
        ]

        createEntities(elements: elements)

        componentsCancellable = entityManager.$components.sink { [weak self] components in
            guard let values = components[String(describing: PhysicsComponent.self)]?.values,
                  let physicsBodies = (Array(values) as? [PhysicsComponent])?.map({ $0.physicsBody }) else {
                return
            }

            self?.physicsWorld.bodies = physicsBodies
        }

        collisionCancellable = physicsWorld.collisionPublisher.sink { [weak self] bodyA, bodyB in
            guard let entities = self?.entityManager.getEntities(for: LightComponent.self) else {
                return
            }

            for entity in entities {
                guard let lightComponent = self?.entityManager.getComponent(LightComponent.self, for: entity),
                      let physicsComponent = self?.entityManager.getComponent(PhysicsComponent.self, for: entity),
                      physicsComponent.physicsBody === bodyA || physicsComponent.physicsBody === bodyB else {
                    continue
                }

                lightComponent.isLit = true
            }
        }
    }

    func createEntities(elements: [Element]) {
        entityFactory.createWall(position: CGPoint(x: 0.5, y: -0.2), size: CGSize(width: 1, height: 0.4))
        entityFactory.createWall(position: CGPoint(x: -0.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))
        entityFactory.createWall(position: CGPoint(x: 1.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))

        entityFactory.createCannon(position: CGPoint(x: 0.5, y: 0.07))

        for element in elements {
            let position = element.position.applying(CGAffineTransform(translationX: 0, y: 0.4))
            let rotation = element.rotation
            let size = element.size

            if let peg = element as? Peg {
                entityFactory.createPeg(position: position, imageName: peg.imageName, rotation: rotation, size: size)
            } else if element is Block {
                entityFactory.createBlock(position: position, rotation: rotation, size: size)
            }
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
              let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: ball) else {
            return
        }

        removePegsWhenBallStuck(ball: ball, physicsComponent: physicsComponent)
        removePegsWhenBallExits(ball: ball, physicsComponent: physicsComponent)
    }

    func removePegsWhenBallStuck(ball: Entity, physicsComponent: PhysicsComponent) {
        // Cancel timer if it turns out ball isn't actually resting
        guard physicsComponent.physicsBody.isResting == true else {
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
                          let lightPhysicsComponent = entityManager.getComponent(PhysicsComponent.self,
                                                                                 for: entity),
                          lightComponent.isLit == true else {
                        continue
                    }

                    let distance = physicsComponent.physicsBody.position
                        .distance(to: lightPhysicsComponent.physicsBody.position)

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

    func removePegsWhenBallExits(ball: Entity, physicsComponent: PhysicsComponent) {
        guard physicsComponent.physicsBody.position.y >= 1.5 else {
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
        systems.forEach { $0.update() }
        removePegs()
    }
}
