final class RenderSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update() {
        let entities = entityManager.getEntities(for: RenderComponent.self)

        for entity in entities {
            guard let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            renderComponent.imageName = renderComponent.imageNames[renderComponent.state] ?? ""
        }
    }
}
