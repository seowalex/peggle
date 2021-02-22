import Combine
import CoreGraphics

final class PhysicsWorld {
    var gravity = CGVector(dx: 0.0, dy: 1.0)
    var speed: CGFloat = 1.0
    var bodies: [PhysicsBody] = []

    var collisionPublisher: AnyPublisher<(PhysicsBody, PhysicsBody), Never> {
        subject.eraseToAnyPublisher()
    }

    private let subject = PassthroughSubject<(PhysicsBody, PhysicsBody), Never>()

    func applyGravity() {
        for body in bodies where body.affectedByGravity == true {
            body.applyForce(body.mass * gravity)
        }
    }

    func updateBodies(deltaTime seconds: CGFloat) {
        for body in bodies where body.isDynamic == true {
            body.update(deltaTime: seconds, speed: speed)
        }
    }

    func resolveCollisions() {
        // Optimises for the assumption that static bodies far outnumber dynamic bodies
        for bodyA in bodies where bodyA.isDynamic {
            for bodyB in bodies {
                guard bodyA !== bodyB && bodyA.isColliding(with: bodyB) else {
                    continue
                }

                subject.send((bodyA, bodyB))

                // TODO: Dynamic collision
                if bodyB.isDynamic == false {
                    resolveStaticCollision(dynamicBody: bodyA, staticBody: bodyB)
                }
            }
        }
    }

    func resolveStaticCollision(dynamicBody: PhysicsBody, staticBody: PhysicsBody) {
        var normalVector = CGVector.zero
        var difference = CGFloat.zero

        // Collision resolution
        if [dynamicBody, staticBody].allSatisfy({ $0.shape == .circle }) {
            normalVector = (dynamicBody.position - staticBody.position).normalized()
            difference = dynamicBody.size.width / 2 + staticBody.size.width / 2
                - dynamicBody.position.distance(to: staticBody.position)
        } else if dynamicBody.shape == .circle && staticBody.shape == .rectangle {
            guard let vertices = staticBody.vertices else {
                return
            }

            // TODO: Check if corner hit is head-on collision
            // First check for corners, then each side
            if let closestVertex = vertices.min(by: { $0.distance(to: dynamicBody.position)
                                                    < $1.distance(to: dynamicBody.position) }),
               dynamicBody.position.distance(to: closestVertex) < dynamicBody.size.width / 2 {
                normalVector = (dynamicBody.position - closestVertex).normalized()
                difference = dynamicBody.size.width / 2 - dynamicBody.position.distance(to: closestVertex)
            } else if dynamicBody.position.distance(to: (vertices[0], vertices[1])) < dynamicBody.size.width / 2 {
                normalVector = (vertices[0] - vertices[2]).normalized()
                difference = dynamicBody.size.width / 2 - dynamicBody.position.distance(to: (vertices[0], vertices[1]))
            } else if dynamicBody.position.distance(to: (vertices[0], vertices[2])) < dynamicBody.size.width / 2 {
                normalVector = (vertices[0] - vertices[1]).normalized()
                difference = dynamicBody.size.width / 2 - dynamicBody.position.distance(to: (vertices[0], vertices[2]))
            } else if dynamicBody.position.distance(to: (vertices[1], vertices[3])) < dynamicBody.size.width / 2 {
                normalVector = (vertices[1] - vertices[0]).normalized()
                difference = dynamicBody.size.width / 2 - dynamicBody.position.distance(to: (vertices[1], vertices[3]))
            } else if dynamicBody.position.distance(to: (vertices[2], vertices[3])) < dynamicBody.size.width / 2 {
                normalVector = (vertices[2] - vertices[0]).normalized()
                difference = dynamicBody.size.width / 2 - dynamicBody.position.distance(to: (vertices[2], vertices[3]))
            }
        }

        dynamicBody.position += normalVector * difference

        // Calculate elastic collision (with restitution)
        let dx = dynamicBody.velocity.dx
        let dy = dynamicBody.velocity.dy
        let angle = normalVector.angle()

        dynamicBody.velocity = (1 - dynamicBody.restitution)
            * CGVector(dx: -dx * cos(2 * angle) - dy * sin(2 * angle),
                       dy: -dx * sin(2 * angle) + dy * cos(2 * angle))
    }

    func update(deltaTime seconds: CGFloat) {
        applyGravity()
        updateBodies(deltaTime: seconds)
        resolveCollisions()
    }
}
