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

    init(pegs: [Peg]) {
        entityFactory = EntityFactory(entityManager: entityManager)
        systems = [
            RenderSystem(entityManager: entityManager),
            LightSystem(entityManager: entityManager),
            TargetSystem(entityManager: entityManager)
        ]

        createEntities(pegs: pegs)

        componentsCancellable = entityManager.$components.sink { [weak self] components in
            guard let values = components[String(describing: PhysicsComponent.self)]?.values,
                  let physicsBodies = (Array(values) as? [PhysicsComponent])?.map({ $0.physicsBody }) else {
                return
            }

            self?.physicsWorld.bodies = physicsBodies
        }

        collisionCancellable = physicsWorld.collisionPublisher.sink { [weak self] physicsBody in
            guard let entities = self?.entityManager.getEntities(for: LightComponent.self) else {
                return
            }

            for entity in entities {
                guard let lightComponent = self?.entityManager.getComponent(LightComponent.self, for: entity),
                      let physicsComponent = self?.entityManager.getComponent(PhysicsComponent.self, for: entity),
                      physicsComponent.physicsBody === physicsBody else {
                    continue
                }

                lightComponent.isLit = true
            }
        }
    }

    func createEntities(pegs: [Peg]) {
        entityFactory.createWall(position: CGPoint(x: 0.5, y: -0.2), size: CGSize(width: 1, height: 0.4))
        entityFactory.createWall(position: CGPoint(x: -0.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))
        entityFactory.createWall(position: CGPoint(x: 1.2, y: 0.7), size: CGSize(width: 0.4, height: 1.4))

        entityFactory.createCannon(position: CGPoint(x: 0.5, y: 0.07))

        for peg in pegs {
            entityFactory.createPeg(position: peg.position, shape: peg.shape, color: peg.color ?? .blue,
                                    rotation: peg.rotation, size: peg.size)
        }
    }

    func getRenderComponents() -> [RenderComponent] {
        entityManager.getComponents(RenderComponent.self)
    }

    func onDrag(position: CGPoint) {
        guard ballEntity == nil else {
            return
        }

        let entities = entityManager.getEntities(for: TargetComponent.self)

        for entity in entities {
            guard let targetComponent = entityManager.getComponent(TargetComponent.self, for: entity) else {
                continue
            }

            targetComponent.target = position
            targetComponent.isTargeting = true
        }
    }

    func onDragEnd(position: CGPoint) {
        guard ballEntity == nil else {
            return
        }

        let entities = entityManager.getEntities(for: TargetComponent.self)

        for entity in entities {
            guard let targetComponent = entityManager.getComponent(TargetComponent.self, for: entity) else {
                continue
            }

            targetComponent.target = nil
            targetComponent.isTargeting = false

            // Clamp the firing angle between minAngle and maxAngle
            let normalizedTarget = position.rotate(around: targetComponent.position,
                                                   by: -targetComponent.initialAngle)
            let angle = targetComponent.position.angle(to: normalizedTarget)
            let clampedAngle = min(max(targetComponent.position.angle(to: normalizedTarget),
                                       targetComponent.minAngle),
                                   targetComponent.maxAngle)
            let difference = clampedAngle - angle
            let actualPosition = position.rotate(around: targetComponent.position, by: difference)

            // Have to normalize the velocity so that the speed remains constant no matter
            // how far the tap is from the cannon
            ballEntity = entityFactory.createBall(position: targetComponent.position,
                                                  velocity: (actualPosition - targetComponent.position)
                                                    .normalized() * 1.2)
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
            ballTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] _ in
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
