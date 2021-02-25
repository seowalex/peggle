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
                    let entities = entityManager.getEntities(for: RemoveComponent.self)
                    let position = physicsComponent.physicsBody.position
                    var minDistance = CGFloat.infinity
                    var minEntity: Entity?

                    for entity in entities {
                        guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity)
                        else {
                            continue
                        }

                        let distance = position.distance(to: physicsComponent.physicsBody.position)

                        if distance < minDistance && physicsComponent.physicsBody.position.y > position.y {
                            minDistance = distance
                            minEntity = entity
                        }
                    }

                    if let entity = minEntity {
                        let ballBody = physicsComponent.physicsBody

                        if let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                           lightComponent.isLit == true {
                            entityManager.removeEntity(entity)
                        } else if let physicsComponent = entityManager
                                    .getComponent(PhysicsComponent.self, for: entity),
                                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) {
                            physicsComponent.physicsBody.affectedByCollisions = false
                            renderComponent.opacity = 0.6

                            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.5) {
                                while true {
                                    if !ballBody.isColliding(with: physicsComponent.physicsBody) {
                                        break
                                    }
                                }

                                physicsComponent.physicsBody.affectedByCollisions = true
                                renderComponent.opacity = 1
                            }
                        }
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
