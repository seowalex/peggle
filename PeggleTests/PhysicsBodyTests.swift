import XCTest
@testable import Peggle

class PhysicsBodyTests: XCTestCase {
    func testConstruct() {
        let shape = PhysicsBody.Shape.circle
        let size = CGSize(width: 2, height: 2)
        let position = CGPoint.zero

        let physicsBody = PhysicsBody(shape: shape, size: size, position: position)

        XCTAssertEqual(physicsBody.shape, shape)
        XCTAssertEqual(physicsBody.size, size)
        XCTAssertEqual(physicsBody.mass, .pi)
        XCTAssertEqual(physicsBody.density, 1)
        XCTAssertEqual(physicsBody.area, .pi)

        XCTAssertEqual(physicsBody.friction, 0.2)
        XCTAssertEqual(physicsBody.restitution, 0.2)
        XCTAssertEqual(physicsBody.linearDamping, 0.1)

        XCTAssertEqual(physicsBody.position, .zero)
        XCTAssertEqual(physicsBody.rotation, 0)
        XCTAssertEqual(physicsBody.velocity, .zero)
        XCTAssertFalse(physicsBody.isResting)

        XCTAssertTrue(physicsBody.affectedByGravity)
        XCTAssertTrue(physicsBody.isDynamic)
        XCTAssertTrue(physicsBody.affectedByCollisions)

        XCTAssertEqual(physicsBody.forces, [])
    }

    func testBoundingBox_rectangle() {
        let size = CGSize(width: 2, height: 2)
        let body = PhysicsBody(shape: .rectangle, size: size, position: CGPoint(x: 1, y: 1))

        XCTAssertEqual(body.boundingBox, CGRect(origin: .zero, size: size))
    }

    func testBoundingBox_rotatedRectangle() {
        let body = PhysicsBody(shape: .rectangle,
                               size: CGSize(width: 2, height: 2),
                               position: CGPoint(x: 1, y: 1),
                               rotation: CGFloat.pi / 4)
        let boundingBox = CGRect(x: 1 - sqrt(2), y: 1 - sqrt(2), width: 2 * sqrt(2), height: 2 * sqrt(2))

        XCTAssertEqual(Float(body.boundingBox.minX), Float(boundingBox.minX))
        XCTAssertEqual(Float(body.boundingBox.maxX), Float(boundingBox.maxX))
        XCTAssertEqual(Float(body.boundingBox.minY), Float(boundingBox.minY))
        XCTAssertEqual(Float(body.boundingBox.maxY), Float(boundingBox.maxY))
    }

    func testBoundingBox_circle() {
        let size = CGSize(width: 2, height: 2)
        let body = PhysicsBody(shape: .circle, size: size, position: CGPoint(x: 1, y: 1))

        XCTAssertEqual(body.boundingBox, CGRect(origin: .zero, size: size))
    }

    func testIsColliding_notCollidingRectangle() {
        let size = CGSize(width: 2, height: 2)
        let body1 = PhysicsBody(shape: .rectangle, size: size, position: .zero)
        let body2 = PhysicsBody(shape: .rectangle, size: size, position: CGPoint(x: 2, y: 0))
        let body3 = PhysicsBody(shape: .rectangle, size: size, position: CGPoint(x: 0, y: 2))

        XCTAssertFalse(body1.isColliding(with: body2))
        XCTAssertFalse(body1.isColliding(with: body3))
        XCTAssertFalse(body2.isColliding(with: body3))
    }

    func testIsColliding_notCollidingRotatedRectangle() {
        let size = CGSize(width: 2, height: 2)
        let body1 = PhysicsBody(shape: .rectangle, size: size, position: .zero, rotation: CGFloat.pi / 4)
        let body2 = PhysicsBody(shape: .rectangle,
                                size: size,
                                position: CGPoint(x: sqrt(2), y: sqrt(2)),
                                rotation: CGFloat.pi / 4)

        XCTAssertFalse(body1.isColliding(with: body2))
    }

    func testIsColliding_collidingRectangle() {
        let size = CGSize(width: 2, height: 2)
        let body1 = PhysicsBody(shape: .rectangle, size: size, position: .zero)
        let body2 = PhysicsBody(shape: .rectangle, size: size, position: CGPoint(x: 1, y: 0))
        let body3 = PhysicsBody(shape: .rectangle, size: size, position: CGPoint(x: 0, y: 1))

        XCTAssertTrue(body1.isColliding(with: body2))
        XCTAssertTrue(body1.isColliding(with: body3))
        XCTAssertTrue(body2.isColliding(with: body3))
    }

    func testIsColliding_collidingRotatedRectangle() {
        let size = CGSize(width: 2, height: 2)
        let body1 = PhysicsBody(shape: .rectangle, size: size, position: .zero, rotation: CGFloat.pi / 4)
        let body2 = PhysicsBody(shape: .rectangle, size: size, position: CGPoint(x: 2, y: 0), rotation: CGFloat.pi / 4)

        XCTAssertTrue(body1.isColliding(with: body2))
    }

    func testIsColliding_notCollidingCircle() {
        let size = CGSize(width: 2, height: 2)
        let body1 = PhysicsBody(shape: .circle, size: size, position: .zero)
        let body2 = PhysicsBody(shape: .circle, size: size, position: CGPoint(x: sqrt(2), y: sqrt(2)))

        XCTAssertFalse(body1.isColliding(with: body2))
    }

    func testIsColliding_collidingCircle() {
        let size = CGSize(width: 2, height: 2)
        let body1 = PhysicsBody(shape: .circle, size: size, position: .zero)
        let body2 = PhysicsBody(shape: .circle, size: size, position: CGPoint(x: 1, y: 1))

        XCTAssertTrue(body1.isColliding(with: body2))
    }

    func testUpdate_oneForce() {
        let body = PhysicsBody(shape: .rectangle, size: CGSize(width: 1, height: 1), position: .zero)

        body.applyForce(CGVector(dx: 1, dy: 1))
        body.update(deltaTime: 1)

        XCTAssertEqual(body.position, CGPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(body.velocity, CGVector(dx: 1, dy: 1))
        XCTAssertEqual(body.forces, [])
    }

    func testUpdate_twoForces() {
        let body = PhysicsBody(shape: .rectangle, size: CGSize(width: 1, height: 1), position: .zero)

        body.applyForce(CGVector(dx: 1, dy: 1))
        body.applyForce(CGVector(dx: 1, dy: -1))
        body.update(deltaTime: 1)

        XCTAssertEqual(body.position, CGPoint(x: 1, y: 0))
        XCTAssertEqual(body.velocity, CGVector(dx: 2, dy: 0))
        XCTAssertEqual(body.forces, [])
    }

    func testUpdate_twoOpposingForces() {
        let body = PhysicsBody(shape: .rectangle, size: CGSize(width: 1, height: 1), position: .zero)

        body.applyForce(CGVector(dx: 1, dy: 1))
        body.applyForce(CGVector(dx: -1, dy: -1))
        body.update(deltaTime: 1)

        XCTAssertEqual(body.position, .zero)
        XCTAssertEqual(body.velocity, .zero)
        XCTAssertEqual(body.forces, [])
    }
}
