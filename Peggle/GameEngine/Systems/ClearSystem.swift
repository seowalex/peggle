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
                    var minDistanceBelow = CGFloat.infinity
                    var minEntityBelow: Entity?

                    for entity in entities {
                        guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity)
                        else {
                            continue
                        }

                        let distance = position.distance(to: physicsComponent.physicsBody.position)

                        if distance < minDistance {
                            minDistance = distance
                            minEntity = entity
                        }

                        if distance < minDistanceBelow && physicsComponent.physicsBody.position.y > position.y {
                            minDistanceBelow = distance
                            minEntityBelow = entity
                        }
                    }

                    // If there are entities below the ball, pick the nearest one
                    // Otherwise, just pick the nearest entity
                    if let entity = minEntity {
                        clearNearestPeg(entity: minEntityBelow ?? entity, body: physicsComponent.physicsBody)
                    }
                }
            }
        } else {
            clearComponent.timer?.invalidate()
            clearComponent.timer = nil
        }
    }

    func clearNearestPeg(entity: Entity, body: PhysicsBody) {
        if let scoreComponent = entityManager.getComponent(ScoreComponent.self, for: entity),
           scoreComponent.isScored == true {
            if let powerComponent = entityManager.getComponent(PowerComponent.self, for: entity) {
                entityManager.removeEntity(entity)
                entityManager.addComponent(powerComponent, to: entity)
            } else {
                entityManager.removeEntity(entity)
            }

            entityManager.addComponent(scoreComponent, to: entity)
        } else if let physicsComponent = entityManager
                    .getComponent(PhysicsComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) {
            physicsComponent.physicsBody.affectedByCollisions = false
            renderComponent.opacity = 0.6

            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.5) {
                while true {
                    if !body.isColliding(with: physicsComponent.physicsBody) {
                        break
                    }
                }

                physicsComponent.physicsBody.affectedByCollisions = true
                renderComponent.opacity = 1
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func clearPegs(entity: Entity, clearComponent: ClearComponent, physicsComponent: PhysicsComponent) {
        guard clearComponent.willClear == true || physicsComponent.physicsBody.position.y > 1.5 else {
            return
        }

        let scoreEntities = entityManager.getEntities(for: ScoreComponent.self)
        var baseScore = 0
        var pegsCount = 0

        for entity in scoreEntities {
            guard let scoreComponent = entityManager.getComponent(ScoreComponent.self, for: entity),
                  scoreComponent.isScored == true else {
                continue
            }

            baseScore += scoreComponent.score
            pegsCount += 1

            if let powerComponent = entityManager.getComponent(PowerComponent.self, for: entity) {
                entityManager.removeEntity(entity)
                entityManager.addComponent(powerComponent, to: entity)
            } else {
                entityManager.removeEntity(entity)
            }
        }

        entityManager.removeEntity(entity)

        let powerComponents = entityManager.getComponents(PowerComponent.self)

        for powerComponent in powerComponents.filter({ $0.isActivated == true }) {
            powerComponent.turnsRemaining -= 1
        }

        let scoreComponents = entityManager.getComponents(ScoreComponent.self)
        let orangePegsCount = scoreComponents.filter { $0.color == .orange && $0.isScored == false }.count

        for scoreComponent in scoreComponents.filter({ $0.color == .purple }) {
            scoreComponent.color = .blue
        }

        scoreComponents.filter { $0.color == .blue }.randomElement()?.color = .purple

        let stateComponents = entityManager.getComponents(StateComponent.self)
        let score = baseScore * pegsCount

        for stateComponent in stateComponents {
            stateComponent.score += score

            // Free balls
            if score >= 25_000 {
                stateComponent.ballsCount += 1
            }

            if score >= 75_000 {
                stateComponent.ballsCount += 1
            }

            if score >= 125_000 {
                stateComponent.ballsCount += 1
            }

            if stateComponent.ballsCount <= 0 || scoreComponents.isEmpty {
                stateComponent.status = .ended(orangePegsCount == 0 ? .won : .lost)
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity

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
