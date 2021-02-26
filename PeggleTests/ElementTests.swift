import XCTest
@testable import Peggle

class ElementTests: XCTestCase {
    func testConstruct() {
        let size = CGSize(width: 2, height: 2)
        let position = CGPoint.zero
        let physicsBody = PhysicsBody(shape: .rectangle, size: size, position: position)

        let element = Element(position: position, rotation: 0.0, size: size, physicsBody: physicsBody)

        XCTAssertEqual(element.position, .zero)
        XCTAssertEqual(element.rotation, 0)
        XCTAssertEqual(element.size, size)
        XCTAssertTrue(element.physicsBody === physicsBody)
    }

    func testSetPosition_setPhysicsBodyPosition() {
        let size = CGSize(width: 2, height: 2)
        let position = CGPoint.zero
        let physicsBody = PhysicsBody(shape: .rectangle, size: size, position: position)

        let element = Element(position: position, rotation: 0.0, size: size, physicsBody: physicsBody)

        element.position = CGPoint(x: 1, y: 1)

        XCTAssertEqual(element.position, physicsBody.position)
    }

    func testSetRotation_setPhysicsBodyRotation() {
        let size = CGSize(width: 2, height: 2)
        let position = CGPoint.zero
        let physicsBody = PhysicsBody(shape: .rectangle, size: size, position: position)

        let element = Element(position: position, rotation: 0.0, size: size, physicsBody: physicsBody)

        element.rotation = CGFloat.pi

        XCTAssertEqual(element.rotation, physicsBody.rotation)
    }

    func testSetSize_setPhysicsBodySize() {
        let size = CGSize(width: 2, height: 2)
        let position = CGPoint.zero
        let physicsBody = PhysicsBody(shape: .rectangle, size: size, position: position)

        let element = Element(position: position, rotation: 0.0, size: size, physicsBody: physicsBody)

        element.size = .zero

        XCTAssertEqual(element.size, physicsBody.size)
    }

    func testSetSize_sizeTooSmall_sizeMinimum() {
        let size = CGSize(width: 2, height: 2)
        let position = CGPoint.zero
        let physicsBody = PhysicsBody(shape: .rectangle, size: size, position: position)

        let element = Element(position: position, rotation: 0.0, size: size, physicsBody: physicsBody)

        element.size = .zero

        XCTAssertEqual(element.size, Element.minimumSize)
    }
}
