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
                  let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                  let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                  powerComponent.isActivated == true else {
                continue
            }

            switch powerComponent.power {
            case .spaceBlast:
                let position = physicsComponent.physicsBody.position
                let entities = entityManager.getEntities(for: LightComponent.self)
                lightComponent.isLit = true

                for entity in entities {
                    guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                          let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                          physicsComponent.physicsBody.position.distance(to: position) < 0.2
                            && lightComponent.isLit == false else {
                        continue
                    }

                    lightComponent.isLit = true
                }

            case .spookyBall:
                print("spoooky")
            }

            powerComponent.isActivated = false
        }
    }
}
