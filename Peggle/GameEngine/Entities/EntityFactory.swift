import SwiftUI

final class EntityFactory {
    private let entityManager: EntityManager

    init(entityManager: EntityManager) {
        self.entityManager = entityManager
    }

    @discardableResult
    func createWall(position: CGPoint, size: CGSize) -> Entity {
        let entity = Entity()
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .rectangle,
                                                                             size: size,
                                                                             position: position,
                                                                             isResting: true,
                                                                             affectedByGravity: false,
                                                                             isDynamic: false)),
                                   to: entity)

        return entity
    }

    @discardableResult
    func createCannon(position: CGPoint, rotation: CGFloat = 0.0) -> Entity {
        let entity = Entity()
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: CGSize(width: 0.16, height: 0.16),
                                                   imageName: "cannon",
                                                   rotation: rotation,
                                                   zIndex: 1),
                                   to: entity)
        entityManager.addComponent(TargetComponent(position: position,
                                                   initialAngle: .pi / 2,
                                                   imageName: "cannon",
                                                   targetedImageName: "cannon-loaded",
                                                   minAngle: -.pi / 3,
                                                   maxAngle: .pi / 3),
                                   to: entity)

        return entity
    }

    @discardableResult
    func createBall(position: CGPoint, size: CGSize = CGSize(width: 0.03, height: 0.03),
                    velocity: CGVector = .zero) -> Entity {
        let entity = Entity()
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .circle,
                                                                             size: size,
                                                                             position: position,
                                                                             restitution: 0.24,
                                                                             velocity: velocity)),
                                   to: entity)
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: size,
                                                   imageName: "ball"),
                                   to: entity)

        return entity
    }

    @discardableResult
    func createPeg(position: CGPoint, shape: Peg.Shape, color: Peg.Color,
                   rotation: CGFloat = 0.0, size: CGSize = Peg.defaultSize) -> Entity {
        var imageName = ""

        switch (shape, color) {
        case (.circle, .blue):
            imageName = "peg-blue"
        case (.circle, .orange):
            imageName = "peg-orange"
        default:
            imageName = ""
        }

        let entity = Entity()
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: PhysicsBody.Shape(shape),
                                                                             size: size,
                                                                             position: position,
                                                                             rotation: rotation,
                                                                             isResting: true,
                                                                             affectedByGravity: false,
                                                                             isDynamic: false)),
                                   to: entity)
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: size,
                                                   imageName: imageName,
                                                   rotation: rotation,
                                                   transition: AnyTransition.opacity
                                                    .animation(.easeInOut(duration: 0.2))),
                                   to: entity)
        entityManager.addComponent(LightComponent(imageName: "\(imageName)-glow"), to: entity)

        return entity
    }
}
