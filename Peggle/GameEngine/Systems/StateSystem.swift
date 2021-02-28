import CoreGraphics

final class StateSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let scoreComponents = entityManager.getComponents(ScoreComponent.self)
        let orangePegCount = scoreComponents.filter { $0.color == .orange && $0.isScored == false }.count
        let stateComponents = entityManager.getComponents(StateComponent.self)

        for stateComponent in stateComponents {
            stateComponent.orangePegsRemainingCount = orangePegCount

            if stateComponent.ballsCount <= 0 || scoreComponents.isEmpty {
                stateComponent.status = .ended(orangePegCount == 0 ? .won : .lost)
            }
        }
    }
}
