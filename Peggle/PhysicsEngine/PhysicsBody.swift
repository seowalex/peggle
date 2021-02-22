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
        if self === body || !boundingBox.intersects(body.boundingBox) {
            return false
        }

        let bodies = [self, body]

        if bodies.allSatisfy({ $0.shape == .rectangle }) {
            let offsetA = CGAffineTransform(translationX: size.width / 2, y: size.height / 2).inverted()
            let rectangleA = CGRect(origin: position.applying(offsetA), size: size)

            let offsetB = CGAffineTransform(translationX: body.size.width / 2, y: body.size.height / 2).inverted()
            let rectangleB = CGRect(origin: body.position.applying(offsetB), size: body.size)

            let verticesA = [
                CGPoint(x: rectangleA.minX, y: rectangleA.minY),
                CGPoint(x: rectangleA.minX, y: rectangleA.maxY),
                CGPoint(x: rectangleA.maxX, y: rectangleA.minY),
                CGPoint(x: rectangleA.maxX, y: rectangleA.maxY)
            ].map { $0.rotate(around: position, by: rotation) }

            let verticesB = [
                CGPoint(x: rectangleB.minX, y: rectangleB.minY),
                CGPoint(x: rectangleB.minX, y: rectangleB.maxY),
                CGPoint(x: rectangleB.maxX, y: rectangleB.minY),
                CGPoint(x: rectangleB.maxX, y: rectangleB.maxY)
            ].map { $0.rotate(around: body.position, by: body.rotation) }

            let axes = [
                verticesA[1] - verticesA[0],
                verticesA[2] - verticesA[0],
                verticesB[1] - verticesB[0],
                verticesB[2] - verticesB[0]
            ].map { $0.normalized() }

            for axis in axes {
                var minA = CGFloat.infinity
                var maxA = -CGFloat.infinity
                var minB = CGFloat.infinity
                var maxB = -CGFloat.infinity

                for vector in verticesA.map({ $0 - CGPoint.zero }) {
                    minA = min(minA, vector.dot(axis))
                    maxA = max(maxA, vector.dot(axis))
                }

                for vector in verticesB.map({ $0 - CGPoint.zero }) {
                    minB = min(minB, vector.dot(axis))
                    maxB = max(maxB, vector.dot(axis))
                }

                if minA - maxB > 0 || minB - maxA > 0 {
                    return false
                }
            }

            return true
        } else if bodies.allSatisfy({ $0.shape == .circle }) {
            return position.distance(to: body.position) < size.width / 2 + body.size.width / 2
        } else if let rectangleBody = bodies.first(where: { $0.shape == .rectangle }),
                  let circleBody = bodies.first(where: { $0.shape == .circle }) {
            let offset = CGAffineTransform(translationX: rectangleBody.size.width / 2,
                                           y: rectangleBody.size.height / 2).inverted()
            let rectangle = CGRect(origin: rectangleBody.position.applying(offset), size: rectangleBody.size)

            let vertices = [
                CGPoint(x: rectangle.minX, y: rectangle.minY),
                CGPoint(x: rectangle.minX, y: rectangle.maxY),
                CGPoint(x: rectangle.maxX, y: rectangle.minY),
                CGPoint(x: rectangle.maxX, y: rectangle.maxY)
            ].map { $0.rotate(around: rectangleBody.position, by: rectangleBody.rotation) }

            guard let closestVertex = vertices.min(by: { $0.distance(to: circleBody.position)
                                                    < $1.distance(to: circleBody.position) }) else {
                return true
            }

            let axes = [
                vertices[1] - vertices[0],
                vertices[2] - vertices[0],
                closestVertex - circleBody.position
            ].map { $0.normalized() }

            for axis in axes {
                let minA = (circleBody.position - CGPoint.zero).dot(axis) - circleBody.size.width / 2
                let maxA = (circleBody.position - CGPoint.zero).dot(axis) + circleBody.size.width / 2
                var minB = CGFloat.infinity
                var maxB = -CGFloat.infinity

                for vector in vertices.map({ $0 - CGPoint.zero }) {
                    minB = min(minB, vector.dot(axis))
                    maxB = max(maxB, vector.dot(axis))
                }

                if minA - maxB > 0 || minB - maxA > 0 {
                    return false
                }
            }

            return true
        }

        return false
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
        case rectangle, circle
    }
}
