import CoreGraphics

final class OscillateSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: OscillateComponent.self)

        for entity in entities {
            guard let oscillateComponent = entityManager.getComponent(OscillateComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            let physicsComponents = entityManager.getComponents(PhysicsComponent.self, for: entity)
            let position = renderComponent.position

            oscillateComponent.time += seconds
            renderComponent.position = oscillateComponent.position + oscillateComponent.amplitude
                * cos(oscillateComponent.angularFrequency * oscillateComponent.time + oscillateComponent.phaseShift)

            for physicsComponent in physicsComponents {
                physicsComponent.physicsBody.position += renderComponent.position - position
                physicsComponent.physicsBody.velocity = -oscillateComponent.amplitude
                    * oscillateComponent.angularFrequency
                    * sin(oscillateComponent.angularFrequency * oscillateComponent.time + oscillateComponent.phaseShift)
            }
        }
    }
}
