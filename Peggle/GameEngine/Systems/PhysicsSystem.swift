final class PhysicsSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update() {
        let entities = entityManager.getEntities(for: RenderComponent.self)

        for entity in entities {
            guard let physicsComponent = entityManager.getComponent(PhysicsComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            renderComponent.position = physicsComponent.physicsBody.position
            renderComponent.rotation = physicsComponent.physicsBody.rotation
            renderComponent.size = physicsComponent.physicsBody.size
        }
    }
}
