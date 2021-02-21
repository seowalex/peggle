import CoreGraphics

final class Peg: Element {
    static let defaultSize = CGSize(width: 0.1, height: 0.1)

    let color: Color

    var imageName: String {
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

    init(position: CGPoint, color: Color, rotation: CGFloat = 0.0, size: CGSize = defaultSize) {
        self.color = color

        super.init(position: position,
                   rotation: rotation,
                   size: size,
                   physicsBody: PhysicsBody(shape: .circle, size: size, position: position))
    }
}

extension Peg {
    enum Color: String, Codable, CaseIterable {
        case blue, orange, green, purple
    }
}
