import CoreGraphics

final class PhysicsBody {
    let shape: Shape
    var size: CGSize
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
        }
    }

    var friction: CGFloat
    var restitution: CGFloat
    var linearDamping: CGFloat

    var position: CGPoint
    var rotation: CGFloat
    var velocity: CGVector
    var isResting: Bool

    var affectedByGravity: Bool
    var isDynamic: Bool
    var affectedByCollisions: Bool

    var forces: [CGVector]

    var boundingBox: CGRect {
        let offset = CGAffineTransform(translationX: size.width / 2, y: size.height / 2).inverted()
        let boundingBox = CGRect(origin: position.applying(offset), size: size)

        switch shape {
        case .rectangle:
            return boundingBox.rotate(by: rotation)
        case .circle:
            return boundingBox
        }
    }
    var vertices: [CGPoint]? {
        guard case .rectangle = shape else {
            return nil
        }

        let offset = CGAffineTransform(translationX: size.width / 2, y: size.height / 2).inverted()
        let rectangle = CGRect(origin: position.applying(offset), size: size)

        return [
            CGPoint(x: rectangle.minX, y: rectangle.minY),
            CGPoint(x: rectangle.minX, y: rectangle.maxY),
            CGPoint(x: rectangle.maxX, y: rectangle.minY),
            CGPoint(x: rectangle.maxX, y: rectangle.maxY)
        ].map { $0.rotate(around: position, by: rotation) }
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
        affectedByCollisions: Bool = true,
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
        self.affectedByCollisions = affectedByCollisions

        self.forces = forces
    }

    static func isColliding(rectangleA: PhysicsBody, rectangleB: PhysicsBody) -> Bool {
        guard let verticesA = rectangleA.vertices, let verticesB = rectangleB.vertices else {
            return true
        }

        let axes = [
            verticesA[1] - verticesA[0],
            verticesA[2] - verticesA[0],
            verticesB[1] - verticesB[0],
            verticesB[2] - verticesB[0]
        ].map { $0.normalized() }

        for axis in axes {
            guard let minA = verticesA.map({ ($0 - CGPoint.zero).dot(axis) }).min(),
                  let maxA = verticesA.map({ ($0 - CGPoint.zero).dot(axis) }).max(),
                  let minB = verticesB.map({ ($0 - CGPoint.zero).dot(axis) }).min(),
                  let maxB = verticesB.map({ ($0 - CGPoint.zero).dot(axis) }).max() else {
                continue
            }

            if minA - maxB > 0 || minB - maxA > 0 {
                return false
            }
        }

        return true
    }

    static func isColliding(rectangle: PhysicsBody, circle: PhysicsBody) -> Bool {
        guard let vertices = rectangle.vertices,
              let closestVertex = vertices.min(by: { $0.distance(to: circle.position)
                                                < $1.distance(to: circle.position) }) else {
            return true
        }

        let axes = [
            vertices[1] - vertices[0],
            vertices[2] - vertices[0],
            closestVertex - circle.position
        ].map { $0.normalized() }

        for axis in axes {
            guard let minA = vertices.map({ ($0 - CGPoint.zero).dot(axis) }).min(),
                  let maxA = vertices.map({ ($0 - CGPoint.zero).dot(axis) }).max() else {
                continue
            }

            let minB = (circle.position - CGPoint.zero).dot(axis) - circle.size.width / 2
            let maxB = (circle.position - CGPoint.zero).dot(axis) + circle.size.width / 2

            if minA - maxB > 0 || minB - maxA > 0 {
                return false
            }
        }

        return true
    }

    func isColliding(with body: PhysicsBody) -> Bool {
        // Handle trivial case first
        if self === body || !boundingBox.intersects(body.boundingBox) {
            return false
        }

        let bodies = [self, body]

        if bodies.allSatisfy({ $0.shape == .rectangle }) {
            return PhysicsBody.isColliding(rectangleA: self, rectangleB: body)
        } else if bodies.allSatisfy({ $0.shape == .circle }) {
            return position.distance(to: body.position) < size.width / 2 + body.size.width / 2
        } else if let rectangle = bodies.first(where: { $0.shape == .rectangle }),
                  let circle = bodies.first(where: { $0.shape == .circle }) {
            return PhysicsBody.isColliding(rectangle: rectangle, circle: circle)
        }

        return true
    }

    func isColliding(with bodies: [PhysicsBody]) -> Bool {
        !bodies.allSatisfy { !isColliding(with: $0) }
    }

    func applyForce(_ force: CGVector) {
        forces.append(force)
    }

    func update(deltaTime seconds: CGFloat, speed: CGFloat = 1.0) {
        let actualSeconds = seconds * speed
        let resultantForce = forces.reduce(CGVector.zero, +)
        let acceleration = resultantForce / mass

        position += velocity * actualSeconds + 0.5 * acceleration * actualSeconds * actualSeconds
        velocity += acceleration * actualSeconds

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
        case rectangle, circle
    }
}
