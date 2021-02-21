import XCTest
import GRDB
@testable import Peggle

class LevelRecordTests: XCTestCase {
    var dbWriter: DatabaseWriter!
    var database: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()

        dbWriter = DatabaseQueue()
        database = try AppDatabase(dbWriter)
    }

    func testConstruct() {
        let name = "Asteroid Blues"
        let level = LevelRecord(name: name)

        XCTAssertEqual(level.name, name)
    }

    func testInsert_validName_success() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        try dbWriter.write { db in
            try level.insert(db)
        }

        XCTAssertNotNil(level.id)
    }

    func testInsert_invalidName_throwsError() throws {
        var level = LevelRecord(name: "")

        try dbWriter.write { db in
            try XCTAssertThrowsError(level.insert(db))
        }
    }

    func testRoundtrip() throws {
        var insertedLevel = LevelRecord(name: "Asteroid Blues")
        let fetchedLevel: LevelRecord? = try dbWriter.write { db in
            try insertedLevel.insert(db)
            return try LevelRecord.fetchOne(db, key: insertedLevel.id)
        }

        XCTAssertEqual(insertedLevel, fetchedLevel)
    }

    func testOrderedByName() throws {
        var level1 = LevelRecord(name: "Asteroid Blues")
        var level2 = LevelRecord(name: "Stray Dog Strut")
        var level3 = LevelRecord(name: "Honky Tonk Women")
        var level4 = LevelRecord(name: "Gateway Shuffle")

        try dbWriter.write { db in
            try level1.insert(db)
            try level2.insert(db)
            try level3.insert(db)
            try level4.insert(db)
        }

        let levels = try dbWriter.read(LevelRecord.all().orderedByName().fetchAll)

        XCTAssertEqual(levels, [level1, level4, level3, level2])
    }
}
