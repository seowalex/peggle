import CoreGraphics

protocol System {
    var entityManager: EntityManager { get }

    init(entityManager: EntityManager)

    func update(deltaTime seconds: CGFloat)
}
