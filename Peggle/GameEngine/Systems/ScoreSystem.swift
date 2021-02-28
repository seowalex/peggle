import CoreGraphics

final class ScoreSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let scoreComponents = entityManager.getComponents(ScoreComponent.self)
        let orangePegsCount = scoreComponents.filter { $0.color == .orange && $0.isScored == false }.count
        let purplePegsCount = scoreComponents.filter { $0.color == .purple }.count
        let entities = entityManager.getEntities(for: ScoreComponent.self)

        // Change random blue peg to purple
        if purplePegsCount == 0 {
            scoreComponents.filter { $0.color == .blue }.randomElement()?.color = .purple
        }

        for entity in entities {
            guard let scoreComponent = entityManager.getComponent(ScoreComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            // Update peg color
            switch scoreComponent.color {
            case .blue:
                renderComponent.imageNames = [.base: "peg-blue", .lit: "peg-blue-glow"]
            case .purple:
                renderComponent.imageNames = [.base: "peg-purple", .lit: "peg-purple-glow"]
            default:
                break
            }

            if scoreComponent.isScored == true {
                renderComponent.state.formUnion(.lit)
            } else {
                switch orangePegsCount {
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
