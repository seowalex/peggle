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

            XCTAssertEqual(columnNames, ["id", "name"])
        }
    }

    func testDatabaseSchema_pegSchema() throws {
        try dbWriter.read { db in
            try XCTAssertTrue(db.tableExists("peg"))
            let columns = try db.columns(in: "peg")
            let columnNames = Set(columns.map { $0.name })

            XCTAssertEqual(columnNames, ["id", "levelId", "position", "rotation", "shape", "size", "color"])
        }
    }

    func testSaveLevel_insertsValidPegs_success() throws {
        var level = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
        ]

        try appDatabase.saveLevel(&level, pegs: &pegs)

        try dbWriter.read { db in
            try XCTAssertTrue(level.exists(db))

            for peg in pegs {
                try XCTAssertTrue(peg.exists(db))
            }
        }
    }

    func testSaveLevel_insertsInvalidPegs_throwsError() throws {
        var level = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        // Pegs that are colliding
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 20, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 20), size: size, shape: .circle, color: .orange)
        ]

        try XCTAssertThrowsError(appDatabase.saveLevel(&level, pegs: &pegs))
    }

    func testSaveLevel_insertsNewLevelOldPegs_throwsError() throws {
        var oldLevel = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
        ]

        try dbWriter.write { db in
            try oldLevel.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = oldLevel.id
                try pegs[index].insert(db)
            }
        }

        var newLevel = Level(name: "Stray Dog Strut")

        // Trying to save a level with another level's pegs should throw an error
        try XCTAssertThrowsError(appDatabase.saveLevel(&newLevel, pegs: &pegs))
    }

    func testSaveLevel_updatesAddPegs_success() throws {
        var level = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level.id
                try pegs[index].insert(db)
            }
        }

        // Add some new pegs
        pegs.append(contentsOf: [
            Peg(position: CGPoint(x: 80, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 80), size: size, shape: .circle, color: .orange)
        ])

        try appDatabase.saveLevel(&level, pegs: &pegs)

        let fetchedPegs = try dbWriter.read(level.pegs.fetchAll)

        XCTAssertEqual(fetchedPegs, pegs)
    }

    func testSaveLevel_updatesEditPegs_success() throws {
        var level = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level.id
                try pegs[index].insert(db)
            }
        }

        // Edit some pegs
        for index in 0..<pegs.count {
            pegs[index].position.x += 40
            pegs[index].position.y += 40
        }

        try appDatabase.saveLevel(&level, pegs: &pegs)

        let fetchedPegs = try dbWriter.read(level.pegs.fetchAll)

        XCTAssertEqual(fetchedPegs, pegs)
    }

    func testSaveLevel_updatesDeletePegs_success() throws {
        var level = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
        ]

        try dbWriter.write { db in
            try level.insert(db)

            for index in 0..<pegs.count {
                pegs[index].levelId = level.id
                try pegs[index].insert(db)
            }
        }

        // Delete some pegs
        pegs.removeLast()

        try appDatabase.saveLevel(&level, pegs: &pegs)

        let fetchedPegs = try dbWriter.read(level.pegs.fetchAll)

        XCTAssertEqual(fetchedPegs, pegs)
    }

    func testDeleteLevels() throws {
        var level1 = Level(name: "Asteroid Blues")
        var level2 = Level(name: "Stray Dog Strut")
        var level3 = Level(name: "Honky Tonk Women")
        var level4 = Level(name: "Gateway Shuffle")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
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
        }

        guard let id1 = level1.id, let id3 = level3.id else {
            XCTFail("Levels should have a non-nil ID after insertion into database")
            return
        }

        try appDatabase.deleteLevels(ids: [id1, id3])

        try dbWriter.read { db in
            try XCTAssertFalse(level1.exists(db))
            try XCTAssertFalse(level3.exists(db))

            // Deleting levels should also delete their associated pegs
            for peg in pegs {
                try XCTAssertFalse(peg.exists(db))
            }
        }

        try XCTAssertEqual(dbWriter.read(Level.fetchCount), 2)
    }

    func testDeleteAllLevels() throws {
        var level1 = Level(name: "Asteroid Blues")
        var level2 = Level(name: "Stray Dog Strut")
        var level3 = Level(name: "Honky Tonk Women")
        var level4 = Level(name: "Gateway Shuffle")

        try dbWriter.write { db in
            try level1.insert(db)
            try level2.insert(db)
            try level3.insert(db)
            try level4.insert(db)
        }

        try appDatabase.deleteAllLevels()

        try XCTAssertEqual(dbWriter.read(Level.fetchCount), 0)
    }

    func testCreateRandomLevelsIfEmpty_emptyDatabase_success() throws {
        try appDatabase.createRandomLevelsIfEmpty()

        try XCTAssertTrue(dbWriter.read(Level.fetchCount) > 0)
    }

    func testCreateRandomLevelsIfEmpty_nonEmptyDatabase_noChange() throws {
        var level = Level(name: "Asteroid Blues")

        try dbWriter.write { db in
            try level.insert(db)
        }

        try appDatabase.createRandomLevelsIfEmpty()

        let levels = try dbWriter.read(Level.fetchAll)

        XCTAssertEqual(levels, [level])
    }

    func testLevelsOrderedByNamePublisher_publishesWellOrderedLevels() throws {
        var level1 = Level(name: "Asteroid Blues")
        var level2 = Level(name: "Stray Dog Strut")

        try dbWriter.write { db in
            try level1.insert(db)
            try level2.insert(db)
        }

        let exp = expectation(description: "Levels")
        var levels: [Level]?
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
        var levels: [Level]?
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
        var level = Level(name: "Asteroid Blues")

        let size = CGSize(width: 40, height: 40)
        var pegs = [
            Peg(position: .zero, size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 40, y: 0), size: size, shape: .circle, color: .blue),
            Peg(position: CGPoint(x: 0, y: 40), size: size, shape: .circle, color: .orange)
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
}
