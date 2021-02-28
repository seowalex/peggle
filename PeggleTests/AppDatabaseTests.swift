// swiftlint:disable type_body_length file_length

import XCTest
import GRDB
@testable import Peggle

class AppDatabaseTests: XCTestCase {
    var dbWriter: DatabaseWriter!
    var appDatabase: AppDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()

        dbWriter = DatabaseQueue()
        appDatabase = try AppDatabase(dbWriter)
    }

    func testDatabaseSchema_levelSchema() throws {
        try dbWriter.read { db in
            try XCTAssertTrue(db.tableExists("level"))
            let columns = try db.columns(in: "level")
            let columnNames = Set(columns.map { $0.name })

            XCTAssertEqual(columnNames, ["id", "name", "isProtected"])
        }
    }

    func testDatabaseSchema_pegSchema() throws {
        try dbWriter.read { db in
            try XCTAssertTrue(db.tableExists("peg"))
            let columns = try db.columns(in: "peg")
            let columnNames = Set(columns.map { $0.name })

            XCTAssertEqual(columnNames, ["id", "levelId", "position", "rotation", "size", "isOscillating",
                                         "minCoefficient", "maxCoefficient", "frequency", "color"])
        }
    }

    func testDatabaseSchema_blockSchema() throws {
        try dbWriter.read { db in
            try XCTAssertTrue(db.tableExists("block"))
            let columns = try db.columns(in: "block")
            let columnNames = Set(columns.map { $0.name })

            XCTAssertEqual(columnNames, ["id", "levelId", "position", "rotation", "size", "isOscillating",
                                         "minCoefficient", "maxCoefficient", "frequency"])
        }
    }

    func testSaveLevel_insertsValidElements_success() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 100, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 140, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 140), size: size)
        ]

        try appDatabase.saveLevel(&level, pegs: &pegs, blocks: &blocks)

        try dbWriter.read { db in
            try XCTAssertTrue(level.exists(db))

            for peg in pegs {
                try XCTAssertTrue(peg.exists(db))
            }

            for block in blocks {
                try XCTAssertTrue(block.exists(db))
            }
        }
    }

    func testSaveLevel_insertsInvalidElements_throwsError() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        // Elements that are colliding
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 0, y: 0), size: size),
            BlockRecord(position: CGPoint(x: 40, y: 0), size: size),
            BlockRecord(position: CGPoint(x: 0, y: 40), size: size)
        ]

        try XCTAssertThrowsError(appDatabase.saveLevel(&level, pegs: &pegs, blocks: &blocks))
    }

    func testSaveLevel_insertsNewLevelWithSameName_overridesOldLevel() throws {
        var oldLevel = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 100, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 140, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 140), size: size)
        ]

        try dbWriter.write { db in
            try oldLevel.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = oldLevel.id
                try pegs[index].insert(db)
            }

            for index in 0..<blocks.count {
                blocks[index].levelId = oldLevel.id
                try blocks[index].insert(db)
            }
        }

        XCTAssertEqual(try dbWriter.read(oldLevel.pegs.fetchCount), 3)
        XCTAssertEqual(try dbWriter.read(oldLevel.blocks.fetchCount), 3)

        var newLevel = LevelRecord(name: "Asteroid Blues")
        var newPegs: [PegRecord] = []
        var newBlocks: [BlockRecord] = []

        try appDatabase.saveLevel(&newLevel, pegs: &newPegs, blocks: &newBlocks)

        XCTAssertEqual(oldLevel.id, newLevel.id)
        XCTAssertEqual(try dbWriter.read(oldLevel.pegs.fetchCount), 0)
        XCTAssertEqual(try dbWriter.read(oldLevel.blocks.fetchCount), 0)
    }

    func testSaveLevel_insertsNewLevelWithSameNameAsProtectedLevel_throwsError() throws {
        var oldLevel = LevelRecord(name: "Asteroid Blues", isProtected: true)

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 100, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 140, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 140), size: size)
        ]

        try dbWriter.write { db in
            try oldLevel.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = oldLevel.id
                try pegs[index].insert(db)
            }

            for index in 0..<blocks.count {
                blocks[index].levelId = oldLevel.id
                try blocks[index].insert(db)
            }
        }

        var newLevel = LevelRecord(name: "Asteroid Blues")
        var newPegs: [PegRecord] = []
        var newBlocks: [BlockRecord] = []

        XCTAssertThrowsError(try appDatabase.saveLevel(&newLevel, pegs: &newPegs, blocks: &newBlocks))
    }

    func testSaveLevel_updatesAddElements_success() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 100, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 140, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 140), size: size)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level.id
                try pegs[index].insert(db)
            }

            for index in 0..<blocks.count {
                blocks[index].levelId = level.id
                try blocks[index].insert(db)
            }
        }

        // Add some new elements
        pegs.append(contentsOf: [
            PegRecord(position: CGPoint(x: 80, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 80), size: size, color: .orange)
        ])

        blocks.append(contentsOf: [
            BlockRecord(position: CGPoint(x: 180, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 180), size: size)
        ])

        try appDatabase.saveLevel(&level, pegs: &pegs, blocks: &blocks)

        let fetchedPegs = try dbWriter.read(level.pegs.fetchAll)
        let fetchedBlocks = try dbWriter.read(level.blocks.fetchAll)

        XCTAssertEqual(fetchedPegs, pegs)
        XCTAssertEqual(fetchedBlocks, blocks)
    }

    func testSaveLevel_updatesDeleteElements_success() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 100, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 140, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 140), size: size)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level.id
                try pegs[index].insert(db)
            }

            for index in 0..<blocks.count {
                blocks[index].levelId = level.id
                try blocks[index].insert(db)
            }
        }

        // Delete some elements
        pegs.removeLast()
        blocks.removeLast()

        try appDatabase.saveLevel(&level, pegs: &pegs, blocks: &blocks)

        let fetchedPegs = try dbWriter.read(level.pegs.fetchAll)
        let fetchedBlocks = try dbWriter.read(level.blocks.fetchAll)

        XCTAssertEqual(fetchedPegs, pegs)
        XCTAssertEqual(fetchedBlocks, blocks)
    }

    func testDeleteLevels() throws {
        var level1 = LevelRecord(name: "Asteroid Blues")
        var level2 = LevelRecord(name: "Stray Dog Strut")
        var level3 = LevelRecord(name: "Honky Tonk Women")
        var level4 = LevelRecord(name: "Gateway Shuffle")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]
        var blocks = [
            BlockRecord(position: CGPoint(x: 100, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 140, y: 100), size: size),
            BlockRecord(position: CGPoint(x: 100, y: 140), size: size)
        ]

        try dbWriter.write { db in
            try level1.insert(db)
            try level2.insert(db)
            try level3.insert(db)
            try level4.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level1.id
                try pegs[index].insert(db)
            }

            for index in 0..<blocks.count {
                blocks[index].levelId = level1.id
                try blocks[index].insert(db)
            }
        }

        guard let id1 = level1.id, let id3 = level3.id else {
            XCTFail("Levels should have a non-nil ID after insertion into database")
            return
        }

        try appDatabase.deleteLevels(ids: [id1, id3])

        try dbWriter.read { db in
            try XCTAssertFalse(level1.exists(db))
            try XCTAssertFalse(level3.exists(db))

            // Deleting levels should also delete their associated elements
            for peg in pegs {
                try XCTAssertFalse(peg.exists(db))
            }

            for block in blocks {
                try XCTAssertFalse(block.exists(db))
            }
        }

        try XCTAssertEqual(dbWriter.read(LevelRecord.fetchCount), 2)
    }

    func testDeleteAllLevels() throws {
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

        try appDatabase.deleteAllLevels()

        try XCTAssertEqual(dbWriter.read(LevelRecord.fetchCount), 0)
    }

    func testLevelsOrderedByNamePublisher_publishesWellOrderedLevels() throws {
        var level1 = LevelRecord(name: "Asteroid Blues")
        var level2 = LevelRecord(name: "Stray Dog Strut")

        try dbWriter.write { db in
            try level1.insert(db)
            try level2.insert(db)
        }

        let exp = expectation(description: "Levels")
        var levels: [LevelRecord]?
        let cancellable = appDatabase.levelsOrderedByNamePublisher().sink { completion in
            if case let .failure(error) = completion {
                XCTFail("Unexpected error \(error)")
            }
        } receiveValue: {
            levels = $0
            exp.fulfill()
        }

        withExtendedLifetime(cancellable) {
            waitForExpectations(timeout: 1, handler: nil)
        }

        XCTAssertEqual(levels, [level1, level2])
    }

    func testLevelsOrderedByNamePublisher_publishesRightOnSubscription() throws {
        var levels: [LevelRecord]?
        _ = appDatabase.levelsOrderedByNamePublisher().sink { completion in
            if case let .failure(error) = completion {
                XCTFail("Unexpected error \(error)")
            }
        } receiveValue: {
            levels = $0
        }

        XCTAssertNotNil(levels)
    }

    func testFetchPegs() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            PegRecord(position: .zero, size: size, color: .blue),
            PegRecord(position: CGPoint(x: 40, y: 0), size: size, color: .blue),
            PegRecord(position: CGPoint(x: 0, y: 40), size: size, color: .orange)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level.id
                try pegs[index].insert(db)
            }
        }

        let fetchedPegs = try appDatabase.fetchPegs(level)

        XCTAssertEqual(fetchedPegs, pegs)
    }

    func testFetchBlocks() throws {
        var level = LevelRecord(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var blocks = [
            BlockRecord(position: .zero, size: size),
            BlockRecord(position: CGPoint(x: 40, y: 0), size: size),
            BlockRecord(position: CGPoint(x: 0, y: 40), size: size)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<blocks.count {
                blocks[index].levelId = level.id
                try blocks[index].insert(db)
            }
        }

        let fetchedBlocks = try appDatabase.fetchBlocks(level)

        XCTAssertEqual(fetchedBlocks, blocks)
    }
}
