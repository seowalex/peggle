import CoreGraphics

final class PhysicsBody {
    let shape: Shape
    let size: CGSize
    var mass: CGFloat {
        get {
            density * area
        }

        set {
            density = newValue / area
        }
    }
    var density: CGFloat
    var area: CGFloat {
        switch shape {
        case .rectangle:
            return size.width * size.height
        case .circle:
            return .pi * (size.width / 2) * (size.height / 2)
        case .triangle:
            return 0.5 * size.width * size.height
        }
    }

    var friction: CGFloat
    var restitution: CGFloat
    var linearDamping: CGFloat

    var position: CGPoint
    let rotation: CGFloat
    var velocity: CGVector
    var isResting: Bool

    var affectedByGravity: Bool
    var isDynamic: Bool

    var forces: [CGVector]

    var boundingBox: CGRect {
        let offset = CGAffineTransform(translationX: size.width / 2, y: size.height / 2).inverted()
        let boundingBox = CGRect(origin: position.applying(offset), size: size)

        // TODO: Handle other shapes
        switch shape {
        case .rectangle:
            return boundingBox.rotate(by: rotation)
        case .circle:
            return boundingBox
        default:
            return .infinite
        }
    }

    init(
        shape: Shape,
        size: CGSize,
        position: CGPoint,
        density: CGFloat = 1.0,
        friction: CGFloat = 0.2,
        restitution: CGFloat = 0.2,
        linearDamping: CGFloat = 0.1,
        rotation: CGFloat = 0.0,
        velocity: CGVector = .zero,
        isResting: Bool = false,
        affectedByGravity: Bool = true,
        isDynamic: Bool = true,
        forces: [CGVector] = []
    ) {
        self.shape = shape
        self.size = size
        self.density = density

        self.friction = friction
        self.restitution = restitution
        self.linearDamping = linearDamping

        self.position = position
        self.rotation = rotation
        self.velocity = velocity
        self.isResting = isResting

        self.affectedByGravity = affectedByGravity
        self.isDynamic = isDynamic

        self.forces = forces
    }

    func isColliding(with body: PhysicsBody) -> Bool {
        // Handle trivial case first
        if !boundingBox.intersects(body.boundingBox) {
            return false
        }

        let bodies = [self, body]

        // TODO: Handle rotation/edge cases (see: Separating Axis Theorem)
        if bodies.allSatisfy({ $0.shape == .rectangle }) {
            return true
        } else if bodies.allSatisfy({ $0.shape == .circle }) {
            return position.distance(to: body.position) < size.width / 2 + body.size.width / 2
        } else if bodies.contains(where: { $0.shape == .rectangle })
                    && bodies.contains(where: { $0.shape == .circle }) {
            return true
        }

        return false
    }

    func applyForce(_ force: CGVector) {
        forces.append(force)
    }

    func update(deltaTime seconds: CGFloat) {
        let resultantForce = forces.reduce(CGVector.zero, +)
        let acceleration = resultantForce / mass

        position += velocity * seconds + 0.5 * acceleration * seconds * seconds
        velocity += acceleration * seconds

        // TODO: Better resting calculations
        if isDynamic == true && velocity.magnitude() < 0.04 {
            isResting = true
        } else if isDynamic == true && velocity.magnitude() > 0.06 {
            isResting = false
        }

        forces.removeAll()
    }
}

extension PhysicsBody {
    enum Shape {
        case rectangle, circle, triangle

        init(_ shape: Peg.Shape) {
            switch shape {
            case .circle:
                self = .circle
            case .triangle:
                self = .triangle
            }
        }
    }
}
