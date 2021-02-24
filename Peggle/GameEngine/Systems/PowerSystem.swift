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

                powerComponent.isActivated = false
            case .spookyBall:
                break
//                let entities = entityManager.getEntities(for: UniqueComponent.self)
//
//                for entity in entities {
//                    guard let uniqueComponent = entityManager.getComponent(UniqueComponent.self, for: entity),
//                          let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
//                          uniqueComponent.kind == .ball && physicsComponent.physicsBody.position.y > 1.4 else {
//                        continue
//                    }
//
//                    physicsComponent.physicsBody.position.y = 0
//                    powerComponent.isActivated = false
//                }
            }
        }
    }
}
