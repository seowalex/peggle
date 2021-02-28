import CoreGraphics

final class ScoreSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let orangePegCount = entityManager.getComponents(ScoreComponent.self)
            .filter { $0.color == .orange && $0.isScored == false }.count
        let entities = entityManager.getEntities(for: ScoreComponent.self)

        for entity in entities {
            guard let scoreComponent = entityManager.getComponent(ScoreComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            if scoreComponent.isScored == true {
                renderComponent.state.formUnion(.lit)
            } else {
                switch orangePegCount {
                case 0:
                    scoreComponent.multiplier = 100
                case 1...3:
                    scoreComponent.multiplier = 10
                case 4...7:
                    scoreComponent.multiplier = 5
                case 8...10:
                    scoreComponent.multiplier = 3
                case 11...15:
                    scoreComponent.multiplier = 2
                default:
                    scoreComponent.multiplier = 1
                }
            }
        }
    }
}
