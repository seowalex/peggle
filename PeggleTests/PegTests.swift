import XCTest
import GRDB
@testable import Peggle

class PegTests: XCTestCase {
    var dbWriter: DatabaseWriter!
    var database: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()

        dbWriter = DatabaseQueue()
        database = try AppDatabase(dbWriter)
    }

    func testConstruct() {
        let position = CGPoint.zero
        let shape = Peg.Shape.allCases.randomElement() ?? .circle
        let color = Peg.Color.allCases.randomElement()

        let peg = Peg(position: position, shape: shape, color: color)

        XCTAssertEqual(peg.position, position)
        XCTAssertEqual(peg.rotation, 0)
        XCTAssertEqual(peg.shape, shape)
        XCTAssertEqual(peg.size, Peg.defaultSize)
        XCTAssertEqual(peg.color, color)
    }

    func testIsColliding_notCollidingPeg() {
        let size = CGSize(width: 40, height: 40)
        let peg1 = Peg(position: .zero, size: size, shape: .circle)
        let peg2 = Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle)
        let peg3 = Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle)

        XCTAssertFalse(peg1.isColliding(with: peg2))
        XCTAssertFalse(peg1.isColliding(with: peg3))
        XCTAssertFalse(peg2.isColliding(with: peg3))
    }

    func testIsColliding_collidingPeg() {
        let size = CGSize(width: 40, height: 40)
        let peg1 = Peg(position: .zero, size: size, shape: .circle)
        let peg2 = Peg(position: CGPoint(x: 20, y: 0), size: size, shape: .circle)
        let peg3 = Peg(position: CGPoint(x: 0, y: 20), size: size, shape: .circle)

        XCTAssertTrue(peg1.isColliding(with: peg2))
        XCTAssertTrue(peg1.isColliding(with: peg3))
        XCTAssertTrue(peg2.isColliding(with: peg3))
    }

    func testIsColliding_notCollidingPegs() {
        let size = CGSize(width: 40, height: 40)
        let peg1 = Peg(position: .zero, size: size, shape: .circle)
        let peg2 = Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle)
        let peg3 = Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle)

        XCTAssertFalse(peg1.isColliding(with: [peg2, peg3]))
        XCTAssertFalse(peg2.isColliding(with: [peg1, peg3]))
        XCTAssertFalse(peg3.isColliding(with: [peg1, peg2]))
    }

    func testIsColliding_collidingPegs() {
        let size = CGSize(width: 40, height: 40)
        let peg1 = Peg(position: .zero, size: size, shape: .circle)
        let peg2 = Peg(position: CGPoint(x: 20, y: 0), size: size, shape: .circle)
        let peg3 = Peg(position: CGPoint(x: 0, y: 20), size: size, shape: .circle)

        XCTAssertTrue(peg1.isColliding(with: [peg2, peg3]))
        XCTAssertTrue(peg2.isColliding(with: [peg1, peg3]))
        XCTAssertTrue(peg3.isColliding(with: [peg1, peg2]))
    }

    func testInsert_validProperties_success() throws {
        var level = Level(name: "Asteroid Blues")
        var peg = Peg(position: .zero, shape: .circle, color: .blue)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try peg.insert(db)
        }

        XCTAssertNotNil(peg.id)
    }

    func testInsert_nilLevelId_throwsError() throws {
        var peg = Peg(position: .zero, shape: .circle, color: .blue)

        try dbWriter.write { db in
            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_invalidLevelId_throwsError() throws {
        var peg = Peg(levelId: 1, position: .zero, shape: .circle, color: .blue)

        try dbWriter.write { db in
            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_invalidRotation_throwsError() throws {
        var level = Level(name: "Asteroid Blues")
        var peg = Peg(position: .zero, rotation: 360, shape: .circle, color: .blue)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_nilColor_throwsError() throws {
        var level = Level(name: "Asteroid Blues")
        var peg = Peg(position: .zero, rotation: 360, shape: .circle)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testRoundtrip() throws {
        var level = Level(name: "Asteroid Blues")
        var insertedPeg = Peg(position: .zero, shape: .circle, color: .blue)
        let fetchedPeg: Peg? = try dbWriter.write { db in
            try level.insert(db)
            insertedPeg.levelId = level.id
            try insertedPeg.insert(db)

            return try Peg.fetchOne(db, key: insertedPeg.id)
        }

        XCTAssertEqual(insertedPeg, fetchedPeg)
    }
}
