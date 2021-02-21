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
        // TODO: Other shapes
        if [dynamicBody, staticBody].allSatisfy({ $0.shape == .circle }) {
            // Collision resolution
            let translationVector = staticBody.position - dynamicBody.position
            let difference = dynamicBody.size.width / 2 + staticBody.size.width / 2
                - dynamicBody.position.distance(to: staticBody.position)

            dynamicBody.position -= translationVector.normalized() * difference

            // Calculate elastic collision (with restitution)
            let dx = dynamicBody.velocity.dx
            let dy = dynamicBody.velocity.dy
            let angle = dynamicBody.position.angle(to: staticBody.position)

            dynamicBody.velocity = (1 - dynamicBody.restitution)
                * CGVector(dx: -dx * cos(2 * angle) - dy * sin(2 * angle),
                           dy: -dx * sin(2 * angle) + dy * cos(2 * angle))
        } else if dynamicBody.shape == .circle && staticBody.shape == .rectangle {
            // TODO: Handle rotation
            let topEdge = CGRect(x: staticBody.boundingBox.minX, y: staticBody.boundingBox.minY,
                                 width: staticBody.boundingBox.width, height: 0)
            let bottomEdge = CGRect(x: staticBody.boundingBox.minX, y: staticBody.boundingBox.maxY,
                                    width: staticBody.boundingBox.width, height: 0)
            let leftEdge = CGRect(x: staticBody.boundingBox.minX, y: staticBody.boundingBox.minY,
                                  width: 0, height: staticBody.boundingBox.height)
            let rightEdge = CGRect(x: staticBody.boundingBox.maxX, y: staticBody.boundingBox.minY,
                                   width: 0, height: staticBody.boundingBox.height)

            if [topEdge, bottomEdge].map(dynamicBody.boundingBox.intersects).contains(true) {
                // Collision resolution
                let translationVector = CGPoint(x: dynamicBody.position.x, y: staticBody.position.y)
                    - dynamicBody.position
                let difference = dynamicBody.size.height / 2 + staticBody.size.height / 2
                    - abs(staticBody.position.y - dynamicBody.position.y)

                dynamicBody.position -= translationVector.normalized() * difference

                // Calculate elastic collision (with restitution)
                dynamicBody.velocity = (1 - dynamicBody.restitution)
                    * CGVector(dx: dynamicBody.velocity.dx,
                               dy: -dynamicBody.velocity.dy)
            }

            if [leftEdge, rightEdge].map(dynamicBody.boundingBox.intersects).contains(true) {
                // Collision resolution
                let translationVector = CGPoint(x: staticBody.position.x, y: dynamicBody.position.y)
                    - dynamicBody.position
                let difference = dynamicBody.size.width / 2 + staticBody.size.width / 2
                    - abs(staticBody.position.x - dynamicBody.position.x)

                dynamicBody.position -= translationVector.normalized() * difference

                // Calculate elastic collision (with restitution)
                dynamicBody.velocity = (1 - dynamicBody.restitution)
                    * CGVector(dx: -dynamicBody.velocity.dx,
                               dy: dynamicBody.velocity.dy)
            }
        }
    }

    func update(deltaTime seconds: CGFloat) {
        applyGravity()
        updateBodies(deltaTime: seconds)
        resolveCollisions()
    }
}
