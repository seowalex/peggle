import CoreGraphics

final class AimSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let entities = entityManager.getEntities(for: AimComponent.self)

        for entity in entities {
            guard let aimComponent = entityManager.getComponent(AimComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            if let target = aimComponent.target {
                // Clamp the rotation between minAngle and maxAngle
                let normalizedTarget = target.rotate(around: aimComponent.position,
                                                     by: -aimComponent.initialAngle)

                renderComponent.rotation = min(max(aimComponent.position.angle(to: normalizedTarget),
                                                   aimComponent.minAngle),
                                               aimComponent.maxAngle)
                renderComponent.state.formUnion(.loaded)
            } else {
                renderComponent.state.subtract(.loaded)
            }
        }
    }
}
