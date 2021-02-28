import CoreGraphics

final class RenderSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: RenderComponent.self)

        for entity in entities {
            guard let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity),
                  let scoreComponent = entityManager.getComponent(ScoreComponent.self, for: entity) else {
                continue
            }

            switch scoreComponent.color {
            case .blue:
                renderComponent.imageNames = [.base: "peg-blue", .lit: "peg-blue-glow"]
            case .purple:
                renderComponent.imageNames = [.base: "peg-purple", .lit: "peg-purple-glow"]
            default:
                break
            }
        }
    }
}
