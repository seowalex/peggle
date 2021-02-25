import CoreGraphics
import Foundation

final class ClearSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func clearPegsWithTimer(clearComponent: ClearComponent, physicsComponent: PhysicsComponent) {
        if physicsComponent.physicsBody.isResting == true {
            if clearComponent.timer == nil || clearComponent.timer?.isValid == false {
                clearComponent.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(clearComponent.speed),
                                                            repeats: false) { [self] _ in
                    let entities = entityManager.getEntities(for: LightComponent.self)
                    let position = physicsComponent.physicsBody.position
                    var minDistance = CGFloat.infinity
                    var minEntity: Entity?

                    for entity in entities {
                        guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                              let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                              lightComponent.isLit == true else {
                            continue
                        }

                        let distance = position.distance(to: physicsComponent.physicsBody.position)

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
        } else {
            clearComponent.timer?.invalidate()
            clearComponent.timer = nil
        }
    }

    func clearPegs(entity: Entity, clearComponent: ClearComponent, physicsComponent: PhysicsComponent) {
        guard clearComponent.willClear == true || physicsComponent.physicsBody.position.y > 1.5 else {
            return
        }

        let lightEntities = entityManager.getEntities(for: LightComponent.self)

        for entity in lightEntities {
            guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                  lightComponent.isLit == true else {
                continue
            }

            if let powerComponent = entityManager.getComponent(PowerComponent.self, for: entity) {
                entityManager.removeEntity(entity)
                entityManager.addComponent(powerComponent, to: entity)
            } else {
                entityManager.removeEntity(entity)
            }
        }

        entityManager.removeEntity(entity)

        let powerEntities = entityManager.getEntities(for: PowerComponent.self)

        for entity in powerEntities {
            guard let powerComponent = entityManager.getComponent(PowerComponent.self, for: entity),
                  powerComponent.isActivated == true else {
                continue
            }

            powerComponent.turnsRemaining -= 1

            if powerComponent.turnsRemaining < 0 {
                entityManager.removeEntity(entity)
            }
        }
    }

    func update(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: ClearComponent.self)

        for entity in entities {
            guard let clearComponent = entityManager.getComponent(ClearComponent.self, for: entity),
                  let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity) else {
                continue
            }

            clearPegsWithTimer(clearComponent: clearComponent, physicsComponent: physicsComponent)
            clearPegs(entity: entity, clearComponent: clearComponent, physicsComponent: physicsComponent)
        }
    }
}
