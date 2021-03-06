import CoreGraphics

final class Peg: Element {
    static let defaultSize = CGSize(width: 0.04, height: 0.04)

    var color: Color

    override var imageName: String {
        switch color {
        case .blue:
            return "peg-blue"
        case .orange:
            return "peg-orange"
        case .green:
            return "peg-green"
        case .purple:
            return "peg-purple"
        }
    }

    init(position: CGPoint, color: Color, rotation: CGFloat = 0.0, size: CGSize = defaultSize,
         isOscillating: Bool = false, minCoefficient: CGFloat = -1.0, maxCoefficient: CGFloat = 1.0,
         frequency: CGFloat = 0.2) {
        self.color = color

        super.init(position: position,
                   rotation: rotation,
                   size: size,
                   isOscillating: isOscillating,
                   minCoefficient: minCoefficient,
                   maxCoefficient: maxCoefficient,
                   frequency: frequency,
                   physicsBody: PhysicsBody(shape: .circle, size: size, position: position, rotation: rotation))
    }
}

extension Peg {
    enum Color: String, Codable, CaseIterable {
        case blue, orange, green, purple
    }
}
