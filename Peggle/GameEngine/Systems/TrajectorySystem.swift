import CoreGraphics

final class TrajectorySystem: System {
    let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    func update(deltaTime seconds: CGFloat) {
        let trajectoryComponents = entityManager.getComponents(TrajectoryComponent.self)

        for trajectoryComponent in trajectoryComponents {
            let renderComponents = entityManager.getComponents(RenderComponent.self, for: trajectoryComponent.entity)

            guard trajectoryComponent.points.sorted() != renderComponents.map({ $0.position }).sorted() else {
                continue
            }

            entityManager.removeEntity(trajectoryComponent.entity)

            for (index, point) in trajectoryComponent.points.enumerated() {
                if index == trajectoryComponent.points.count - 1 {
                    entityManager.addComponent(RenderComponent(position: point,
                                                               size: trajectoryComponent.size,
                                                               imageName: "ball",
                                                               opacity: 0.6),
                                               to: trajectoryComponent.entity)
                } else {
                    entityManager.addComponent(RenderComponent(position: point,
                                                               size: CGSize(width: 0.01, height: 0.01),
                                                               imageName: "ball",
                                                               opacity: 0.6),
                                               to: trajectoryComponent.entity)
                }
            }
        }
    }
}
