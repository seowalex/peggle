import XCTest
import GRDB
@testable import Peggle

class BlockRecordTests: XCTestCase {
    var dbWriter: DatabaseWriter!
    var database: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()

        dbWriter = DatabaseQueue()
        database = try AppDatabase(dbWriter)
    }

    func testConstruct() {
        let position = CGPoint.zero

        let block = BlockRecord(position: position)

        XCTAssertEqual(block.position, position)
        XCTAssertEqual(block.rotation, 0)
        XCTAssertEqual(block.size, Block.defaultSize)
    }

    func testInsert_validProperties_success() throws {
        var level = LevelRecord(name: "Asteroid Blues")
        var block = BlockRecord(position: .zero)

        try dbWriter.write { db in
            try level.insert(db)
            block.levelId = level.id

            try block.insert(db)
        }

        XCTAssertNotNil(block.id)
    }

    func testInsert_nilLevelId_throwsError() throws {
        var block = BlockRecord(position: .zero)

        try dbWriter.write { db in
            try XCTAssertThrowsError(block.insert(db))
        }
    }

    func testInsert_invalidLevelId_throwsError() throws {
        var block = BlockRecord(levelId: 1, position: .zero)

        try dbWriter.write { db in
            try XCTAssertThrowsError(block.insert(db))
        }
    }

    func testInsert_invalidRotation_throwsError() throws {
        var level = LevelRecord(name: "Asteroid Blues")
        var block = BlockRecord(position: .zero, rotation: -CGFloat.pi)

        try dbWriter.write { db in
            try level.insert(db)
            block.levelId = level.id

            try XCTAssertThrowsError(block.insert(db))
        }
    }

    func testRoundtrip() throws {
        var level = LevelRecord(name: "Asteroid Blues")
        var insertedBlock = BlockRecord(position: .zero)
        let fetchedBlock: BlockRecord? = try dbWriter.write { db in
            try level.insert(db)
            insertedBlock.levelId = level.id
            try insertedBlock.insert(db)

            return try BlockRecord.fetchOne(db, key: insertedBlock.id)
        }

        XCTAssertEqual(insertedBlock, fetchedBlock)
    }
}
