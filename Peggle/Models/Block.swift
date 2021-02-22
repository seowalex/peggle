import CoreGraphics

final class Block: Element {
    static let defaultSize = CGSize(width: 0.04, height: 0.04)

    override var imageName: String {
        "block"
    }

    init(position: CGPoint, rotation: CGFloat = 0.0, size: CGSize = defaultSize) {
        super.init(position: position,
                   rotation: rotation,
                   size: size,
                   physicsBody: PhysicsBody(shape: .rectangle, size: size, position: position, rotation: rotation))
    }
}
