final class LightSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update() {
        let entities = entityManager.getEntities(for: LightComponent.self)

        for entity in entities {
            guard let lightComponent = entityManager.getComponent(LightComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity),
                  lightComponent.isLit == true else {
                continue
            }

            renderComponent.state.formUnion(.lit)
        }
    }
}
