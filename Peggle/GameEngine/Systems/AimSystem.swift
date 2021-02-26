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
                let normalizedTarget = target.rotate(around: aimComponent.position, by: -aimComponent.initialAngle)
                let angle = aimComponent.position.angle(to: normalizedTarget)
                let clampedAngle = min(max(angle, aimComponent.minAngle), aimComponent.maxAngle)
                let difference = clampedAngle - angle
                let actualTarget = target.rotate(around: aimComponent.position, by: difference)

                // Have to normalize the velocity so that the speed remains constant no matter
                // how far the tap is from the cannon
                aimComponent.velocity = (actualTarget - aimComponent.position).normalized()

                renderComponent.rotation = clampedAngle
                renderComponent.state.formUnion(.loaded)
            } else {
                aimComponent.velocity = nil
                renderComponent.state.subtract(.loaded)
            }
        }
    }
}
