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
                  powerComponent.isActivated == true && powerComponent.hasBeenActivated == false else {
                continue
            }

            switch powerComponent.power {
            case .spaceBlast:
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

                powerComponent.hasBeenActivated = true
            case .spookyBall:
                let entities = entityManager.getEntities(for: ClearComponent.self)

                for entity in entities {
                    guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                          physicsComponent.physicsBody.position.y > 1.4 else {
                        continue
                    }

                    physicsComponent.physicsBody.position.y = 0
                    powerComponent.hasBeenActivated = true
                }
            }
        }
    }
}
