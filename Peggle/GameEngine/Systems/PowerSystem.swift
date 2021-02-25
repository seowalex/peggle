import CoreGraphics

final class PowerSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: PowerComponent.self)

        for entity in entities {
            guard let powerComponent = entityManager.getComponent(PowerComponent.self, for: entity),
                  powerComponent.isActivated == true else {
                continue
            }

            switch (powerComponent.power, powerComponent.turnsRemaining) {
            case (.superGuide, let turnsRemaining) where turnsRemaining > -1:
                let entities = entityManager.getEntities(for: TrajectoryComponent.self)

                for entity in entities {
                    guard let trajectoryComponent = entityManager
                            .getComponent(TrajectoryComponent.self, for: entity) else {
                        continue
                    }

                    if turnsRemaining > 0 {
                        trajectoryComponent.maxCollisions = 2
                    } else {
                        trajectoryComponent.maxCollisions = 1
                    }
                }
            case (.spaceBlast, let turnsRemaining) where turnsRemaining > 0:
                guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity) else {
                    break
                }

                let position = physicsComponent.physicsBody.position
                let entities = entityManager.getEntities(for: LightComponent.self)

                for entity in entities {
                    guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                          let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                          physicsComponent.physicsBody.position.distance(to: position) < 0.2
                            && lightComponent.isLit == false else {
                        continue
                    }

                    lightComponent.isLit = true
                }

                powerComponent.turnsRemaining -= 1
            case (.spookyBall, let turnsRemaining) where turnsRemaining > 0:
                let entities = entityManager.getEntities(for: ClearComponent.self)

                for entity in entities {
                    guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                          physicsComponent.physicsBody.position.y > 1.4 else {
                        continue
                    }

                    physicsComponent.physicsBody.position.y = 0
                    powerComponent.turnsRemaining -= 1
                }
            default:
                break
            }
        }
    }
}
