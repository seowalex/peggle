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
                                                   imageNames: [.base: "cannon", .loaded: "cannon-loaded"],
                                                   rotation: rotation,
                                                   zIndex: 1),
                                   to: entity)
        entityManager.addComponent(AimComponent(position: position,
                                                initialAngle: .pi / 2,
                                                minAngle: -.pi / 3,
                                                maxAngle: .pi / 3),
                                   to: entity)
        entityManager.addComponent(TrajectoryComponent(shape: .circle,
                                                       size: CGSize(width: 0.03, height: 0.03)),
                                   to: entity)

        return entity
    }

    @discardableResult
    func createBall(position: CGPoint, size: CGSize = CGSize(width: 0.03, height: 0.03),
                    velocity: CGVector = .zero, physicsSpeed: CGFloat = 1.0) -> Entity {
        let entity = Entity()
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .circle,
                                                                             size: size,
                                                                             position: position,
                                                                             velocity: velocity)),
                                   to: entity)
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: size,
                                                   imageName: "ball"),
                                   to: entity)
        entityManager.addComponent(ClearComponent(speed: physicsSpeed), to: entity)

        return entity
    }

    @discardableResult
    func createPeg(position: CGPoint, color: Peg.Color, imageName: String, rotation: CGFloat = 0.0,
                   size: CGSize = Peg.defaultSize, isOscillating: Bool = false, minCoefficient: CGFloat = -1.0,
                   maxCoefficient: CGFloat = 1.0, frequency: CGFloat = 0.4) -> Entity {
        let entity = Entity()
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .circle,
                                                                             size: size,
                                                                             position: position,
                                                                             rotation: rotation,
                                                                             isResting: !isOscillating,
                                                                             affectedByGravity: false,
                                                                             isDynamic: false)),
                                   to: entity)
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: size,
                                                   imageNames: [.base: imageName, .lit: "\(imageName)-glow"],
                                                   rotation: rotation,
                                                   transition: AnyTransition.opacity
                                                    .animation(.easeInOut(duration: 0.2))),
                                   to: entity)
        entityManager.addComponent(ScoreComponent(color: color), to: entity)
        entityManager.addComponent(RemoveComponent(), to: entity)

        if isOscillating == true {
            let startPoint = (position + CGVector(dx: minCoefficient * size.width, dy: 0))
                .rotate(around: position, by: rotation)
            let endPoint = (position + CGVector(dx: maxCoefficient * size.width, dy: 0))
                .rotate(around: position, by: rotation)

            entityManager.addComponent(OscillateComponent(position: position,
                                                          startPoint: startPoint,
                                                          endPoint: endPoint,
                                                          frequency: frequency),
                                       to: entity)
        }

        return entity
    }

    @discardableResult
    func createBlock(position: CGPoint, rotation: CGFloat = 0.0, size: CGSize = Block.defaultSize,
                     isOscillating: Bool = false, minCoefficient: CGFloat = -1.0, maxCoefficient: CGFloat = 1.0,
                     frequency: CGFloat = 0.4) -> Entity {
        let entity = Entity()
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .rectangle,
                                                                             size: size,
                                                                             position: position,
                                                                             rotation: rotation,
                                                                             isResting: !isOscillating,
                                                                             affectedByGravity: false,
                                                                             isDynamic: false)),
                                   to: entity)
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: size,
                                                   imageName: "block",
                                                   rotation: rotation),
                                   to: entity)
        entityManager.addComponent(RemoveComponent(), to: entity)

        if isOscillating == true {
            let startPoint = (position + CGVector(dx: minCoefficient * size.width, dy: 0))
                .rotate(around: position, by: rotation)
            let endPoint = (position + CGVector(dx: maxCoefficient * size.width, dy: 0))
                .rotate(around: position, by: rotation)

            entityManager.addComponent(OscillateComponent(position: position,
                                                          startPoint: startPoint,
                                                          endPoint: endPoint,
                                                          frequency: frequency),
                                       to: entity)
        }

        return entity
    }

    @discardableResult
    func createBucket(position: CGPoint, startPoint: CGPoint, endPoint: CGPoint, frequency: CGFloat) -> Entity {
        let entity = Entity()
        entityManager.addComponent(OscillateComponent(position: position,
                                                      startPoint: startPoint,
                                                      endPoint: endPoint,
                                                      frequency: frequency),
                                   to: entity)
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .rectangle,
                                                                             size: CGSize(width: 0.2, height: 0.04),
                                                                             position: position,
                                                                             affectedByGravity: false,
                                                                             isDynamic: false,
                                                                             affectedByCollisions: false)),
                                   to: entity)
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .rectangle,
                                                                             size: CGSize(width: 0.02, height: 0.06),
                                                                             position: position
                                                                                + CGVector(dx: -0.11, dy: 0.002),
                                                                             affectedByGravity: false,
                                                                             isDynamic: false)),
                                   to: entity)
        entityManager.addComponent(PhysicsComponent(physicsBody: PhysicsBody(shape: .rectangle,
                                                                             size: CGSize(width: 0.02, height: 0.06),
                                                                             position: position
                                                                                + CGVector(dx: 0.11, dy: 0.002),
                                                                             affectedByGravity: false,
                                                                             isDynamic: false)),
                                   to: entity)
        entityManager.addComponent(RenderComponent(position: position,
                                                   size: CGSize(width: 0.24, height: 0.08),
                                                   imageName: "bucket",
                                                   zIndex: 1),
                                   to: entity)

        return entity
    }
}
