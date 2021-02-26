import CoreGraphics

final class Block: Element {
    static let defaultSize = CGSize(width: 0.04, height: 0.04)

    override var imageName: String {
        "block"
    }

    init(position: CGPoint, rotation: CGFloat = 0.0, size: CGSize = defaultSize, isOscillating: Bool = false,
         minCoefficient: CGFloat = -1.0, maxCoefficient: CGFloat = 1.0, frequency: CGFloat = 0.4) {
        super.init(position: position,
                   rotation: rotation,
                   size: size,
                   isOscillating: isOscillating,
                   minCoefficient: minCoefficient,
                   maxCoefficient: maxCoefficient,
                   frequency: frequency,
                   physicsBody: PhysicsBody(shape: .rectangle, size: size, position: position, rotation: rotation))
    }
}
