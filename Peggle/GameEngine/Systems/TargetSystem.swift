final class TargetSystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update() {
        let entities = entityManager.getEntities(for: TargetComponent.self)

        for entity in entities {
            guard let targetComponent = entityManager.getComponent(TargetComponent.self, for: entity),
                  let renderComponent = entityManager.getComponent(RenderComponent.self, for: entity) else {
                continue
            }

            if let target = targetComponent.target {
                // Clamp the rotation between minAngle and maxAngle
                let normalizedTarget = target.rotate(around: targetComponent.position,
                                                     by: -targetComponent.initialAngle)

                renderComponent.rotation = min(max(targetComponent.position.angle(to: normalizedTarget),
                                                   targetComponent.minAngle),
                                               targetComponent.maxAngle)
            }

            if targetComponent.isTargeting == true {
                renderComponent.imageName = targetComponent.targetedImageName
            } else {
                renderComponent.imageName = targetComponent.imageName
            }
        }
    }
}
