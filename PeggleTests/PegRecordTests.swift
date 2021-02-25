import XCTest
import GRDB
@testable import Peggle

class PegRecordTests: XCTestCase {
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

        let peg = PegRecord(position: position, color: color)

        XCTAssertEqual(peg.position, position)
        XCTAssertEqual(peg.rotation, 0)
        XCTAssertEqual(peg.size, Peg.defaultSize)
        XCTAssertEqual(peg.color, color)
    }

    func testInsert_validProperties_success() throws {
        var level = LevelRecord(name: "Asteroid Blues")
        var peg = PegRecord(position: .zero, color: .blue)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try peg.insert(db)
        }

        XCTAssertNotNil(peg.id)
    }

    func testInsert_nilLevelId_throwsError() throws {
        var peg = PegRecord(position: .zero, color: .blue)

        try dbWriter.write { db in
            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_invalidLevelId_throwsError() throws {
        var peg = PegRecord(levelId: 1, position: .zero, color: .blue)

        try dbWriter.write { db in
            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testInsert_invalidRotation_throwsError() throws {
        var level = LevelRecord(name: "Asteroid Blues")
        var peg = PegRecord(position: .zero, rotation: -CGFloat.pi, color: .blue)

        try dbWriter.write { db in
            try level.insert(db)
            peg.levelId = level.id

            try XCTAssertThrowsError(peg.insert(db))
        }
    }

    func testRoundtrip() throws {
        var level = LevelRecord(name: "Asteroid Blues")
        var insertedPeg = PegRecord(position: .zero, color: .blue)
        let fetchedPeg: PegRecord? = try dbWriter.write { db in
            try level.insert(db)
            insertedPeg.levelId = level.id
            try insertedPeg.insert(db)

            return try PegRecord.fetchOne(db, key: insertedPeg.id)
        }

        XCTAssertEqual(insertedPeg, fetchedPeg)
    }
}
