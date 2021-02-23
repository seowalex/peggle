import CoreGraphics

final class RenderSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let renderComponents = entityManager.getComponents(RenderComponent.self)

        for renderComponent in renderComponents {
            renderComponent.imageName = renderComponent.imageNames[renderComponent.state] ?? ""
        }
    }
}
