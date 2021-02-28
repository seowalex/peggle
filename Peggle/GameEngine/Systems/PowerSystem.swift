import CoreGraphics

final class PowerSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func superGuide(turnsRemaining: Int) {
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
    }

    func spaceBlast(entity: Entity, powerComponent: PowerComponent) {
        guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity) else {
            return
        }

        let position = physicsComponent.physicsBody.position
        let entities = entityManager.getEntities(for: ScoreComponent.self)

        for entity in entities {
            guard let scoreComponent = entityManager.getComponent(ScoreComponent.self, for: entity),
                  let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                  physicsComponent.physicsBody.position.distance(to: position) < 0.2
                    && scoreComponent.isScored == false else {
                continue
            }

            scoreComponent.isScored = true
        }

        powerComponent.turnsRemaining -= 1
    }

    func spookyBall(powerComponent: PowerComponent) {
        let entities = entityManager.getEntities(for: ClearComponent.self)

        for entity in entities {
            guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                  physicsComponent.physicsBody.position.y > 1.4 else {
                continue
            }

            physicsComponent.physicsBody.position.y = 0
            powerComponent.turnsRemaining -= 1
        }
    }

    func update(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: PowerComponent.self)

        for entity in entities {
            guard let powerComponent = entityManager.getComponent(PowerComponent.self, for: entity),
                  powerComponent.isActivated == true else {
                continue
            }

            if powerComponent.turnsRemaining < 0 {
                entityManager.removeEntity(entity)
            }

            switch (powerComponent.power, powerComponent.turnsRemaining) {
            case (.superGuide, let turnsRemaining) where turnsRemaining > -1:
                superGuide(turnsRemaining: turnsRemaining)
            case (.spaceBlast, let turnsRemaining) where turnsRemaining > 0:
                spaceBlast(entity: entity, powerComponent: powerComponent)
            case (.spookyBall, let turnsRemaining) where turnsRemaining > 0:
                spookyBall(powerComponent: powerComponent)
            default:
                break
            }
        }
    }
}
