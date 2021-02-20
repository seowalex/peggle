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
        let color = Peg.Color.allCases.randomElement() ?? .blue

        let peg = Peg(position: position, color: color)

        XCTAssertEqual(peg.position, position)
        XCTAssertEqual(peg.rotation, 0)
        XCTAssertEqual(peg.size, Peg.defaultSize)
        XCTAssertEqual(peg.color, color)
    }

    func testInsert_validProperties_success() throws {
        var level = Level(name: "Asteroid Blues")
        var peg = Peg(position: .zero, color: .blue)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try peg.insert(db)
        }

        XCTAssertNotNil(peg.id)
    }

    func testInsert_nilLevelId_throwsError() throws {
        var peg = Peg(position: .zero, color: .blue)

        try dbWriter.write { db in
            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_invalidLevelId_throwsError() throws {
        var peg = Peg(levelId: 1, position: .zero, color: .blue)

        try dbWriter.write { db in
            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_invalidRotation_throwsError() throws {
        var level = Level(name: "Asteroid Blues")
        var peg = Peg(position: .zero, rotation: 360, color: .blue)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testRoundtrip() throws {
        var level = Level(name: "Asteroid Blues")
        var insertedPeg = Peg(position: .zero, color: .blue)
        let fetchedPeg: Peg? = try dbWriter.write { db in
            try level.insert(db)
            insertedPeg.levelId = level.id
            try insertedPeg.insert(db)

            return try Peg.fetchOne(db, key: insertedPeg.id)
        }

        XCTAssertEqual(insertedPeg, fetchedPeg)
    }
}
