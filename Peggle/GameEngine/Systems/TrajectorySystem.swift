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

            for point in trajectoryComponent.points {
                entityManager.addComponent(RenderComponent(position: point,
                                                           size: CGSize(width: 0.01, height: 0.01),
                                                           imageName: "ball"),
                                           to: trajectoryComponent.entity)
            }
        }
    }
}
