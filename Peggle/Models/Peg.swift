import CoreGraphics

final class Peg {
    static let defaultSize = CGSize(width: 0.04, height: 0.04)

    var position: CGPoint {
        didSet {
            physicsBody.position = position
        }
    }
    var rotation: CGFloat {
        didSet {
            physicsBody.rotation = rotation
        }
    }
    var size: CGSize {
        didSet {
            physicsBody.size = size
        }
    }
    let color: Color

    var physicsBody: PhysicsBody
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
        self.position = position
        self.rotation = rotation
        self.size = size
        self.color = color

        self.physicsBody = PhysicsBody(shape: .circle, size: size, position: position)
    }
}

extension Peg {
    enum Color: String, Codable, CaseIterable {
        case blue, orange, green, purple
    }
}

 extension Peg: Hashable {
    static func == (lhs: Peg, rhs: Peg) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
 }
