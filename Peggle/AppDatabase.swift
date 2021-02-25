import Combine
import CoreGraphics
import GRDB

struct AppDatabase {
    private let dbWriter: DatabaseWriter

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // swiftlint:disable empty_string
        migrator.registerMigration("CreateLevel") { db in
            try db.create(table: "level") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text)
                    .notNull()
                    .unique(onConflict: .replace)
                    .check { $0 != "" }
                    .collate(.localizedStandardCompare)
                t.column("isProtected", .boolean)
                    .notNull()
            }
        }
        // swiftlint:enable empty_string

        migrator.registerMigration("CreatePeg") { db in
            try db.create(table: "peg") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("levelId", .integer)
                    .notNull()
                    .indexed()
                    .references("level", onDelete: .cascade)
                t.column("position", .text)
                    .notNull()
                t.column("rotation", .double)
                    .notNull()
                    .check { -Double.pi < $0 && $0 <= Double.pi }
                t.column("size", .text)
                    .notNull()
                t.column("color", .text)
                    .notNull()
                    .check { Peg.Color.allCases.map { $0.rawValue }.contains($0) }
            }
        }

        migrator.registerMigration("CreateBlock") { db in
            try db.create(table: "block") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("levelId", .integer)
                    .notNull()
                    .indexed()
                    .references("level", onDelete: .cascade)
                t.column("position", .text)
                    .notNull()
                t.column("rotation", .double)
                    .notNull()
                    .check { -Double.pi < $0 && $0 <= Double.pi }
                t.column("size", .text)
                    .notNull()
            }
        }

        // Setting up preloaded levels take a non-trivial amount of code but it's not reusable
        // swiftlint:disable closure_body_length
        migrator.registerMigration("CreatePreloadedLevel1") { db in
            var level = LevelRecord(name: "Peggleland", isProtected: true)
            try level.save(db)

            guard let levelId = level.id else {
                throw DatabaseError(message: "Preloaded levels could not be created")
            }

            let colors = (Array(repeating: Peg.Color.orange, count: 25) + Array(repeating: Peg.Color.blue, count: 35))
                .shuffled()

            for i in 0..<6 {
                for j in 0..<10 {
                    var peg = PegRecord(levelId: levelId,
                                        position: CGPoint(x: 0.27 + CGFloat(i) * 0.42 / 5
                                                            + (j.isMultiple(of: 2) ? 0.04 : 0),
                                                          y: 0.1 + CGFloat(j) * 0.7 / 9),
                                        color: colors[i * 10 + j])
                    try peg.save(db)
                }
            }

            for i in 0..<2 {
                for j in 0..<4 {
                    var block = BlockRecord(levelId: levelId,
                                            position: CGPoint(x: 0.1 + CGFloat(i) * 0.8,
                                                              y: 0.16 + CGFloat(j) * 1.4 / 9
                                                                + (i.isMultiple(of: 2) ? 0.7 / 9 : 0)),
                                            rotation: (i.isMultiple(of: 2) ? 1 : -1) * CGFloat.pi / 8,
                                            size: CGSize(width: 0.2, height: 0.04))
                    try block.save(db)
                }
            }
        }

        migrator.registerMigration("CreatePreloadedLevel2") { db in
            var level = LevelRecord(name: "Spiderweb", isProtected: true)
            try level.save(db)

            guard let levelId = level.id else {
                throw DatabaseError(message: "Preloaded levels could not be created")
            }

            let colors = (Array(repeating: Peg.Color.orange, count: 25) + Array(repeating: Peg.Color.blue, count: 35))
                .shuffled()
            var index = 1

            var peg = PegRecord(levelId: levelId,
                                position: CGPoint(x: 0.5, y: 0.5),
                                color: colors[0])
            try peg.save(db)

            for i in 1...2 {
                for j in 0..<(i * 5) {
                    var peg = PegRecord(levelId: levelId,
                                        position: CGPoint(x: 0.5 + CGFloat(i) * 0.08, y: 0.5)
                                            .rotate(around: CGPoint(x: 0.5, y: 0.5),
                                                    by: CGFloat(j) / (CGFloat(i) * 5) * 2 * CGFloat.pi),
                                        color: colors[index])
                    try peg.save(db)

                    index += 1
                }
            }

            for i in 0..<2 {
                for j in -2...2 {
                    for k in 0..<(4 + max(abs(j) - 1, 0)) {
                        var peg = PegRecord(levelId: levelId,
                                            position: CGPoint(x: 0.5 + (0.24 + CGFloat(k) * 0.08)
                                                                * (i.isMultiple(of: 2) ? 1 : -1),
                                                              y: 0.5)
                                                .rotate(around: CGPoint(x: 0.5, y: 0.5),
                                                        by: CGFloat(j) * CGFloat.pi / 10),
                                            color: colors[index])
                        try peg.save(db)

                        index += 1
                    }
                }
            }
        }

        migrator.registerMigration("CreatePreloadedLevel3") { db in
            var level = LevelRecord(name: "Croco-Gator Pit", isProtected: true)
            try level.save(db)

            guard let levelId = level.id else {
                throw DatabaseError(message: "Preloaded levels could not be created")
            }
        }
        // swiftlint:enable closure_body_length

        return migrator
    }

    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
}

// MARK: - Database Access: Writes

extension AppDatabase {
    func isPreloadedLevel(name: String) throws -> Bool {
        try dbWriter.read { db in
            try LevelRecord
                .filter(LevelRecord.Columns.isProtected == true && LevelRecord.Columns.name == name)
                .fetchCount(db) > 0
        }
    }

    func saveLevel(_ level: inout LevelRecord, pegs: inout [PegRecord], blocks: inout [BlockRecord]) throws {
        try dbWriter.write { db in
            level = try LevelRecord.filter(LevelRecord.Columns.name == level.name).fetchOne(db) ?? level

            guard level.isProtected == false else {
                throw DatabaseError(message: "Preloaded levels cannot be overriden")
            }

            try level.save(db)
            try level.pegs.deleteAll(db)
            try level.blocks.deleteAll(db)

            let bodies = pegs.map { PhysicsBody(shape: .circle, size: $0.size,
                                                position: $0.position, rotation: $0.rotation)
            } + blocks.map { PhysicsBody(shape: .rectangle, size: $0.size,
                                         position: $0.position, rotation: $0.rotation)
            }

            guard bodies.allSatisfy({ !$0.isColliding(with: bodies) }) else {
                throw DatabaseError(message: "Pegs/blocks are colliding with each other")
            }

            for index in pegs.indices {
                pegs[index].levelId = level.id
                try pegs[index].save(db)
            }

            for index in blocks.indices {
                blocks[index].levelId = level.id
                try blocks[index].save(db)
            }
        }
    }

    func deleteLevels(ids: [Int64]) throws {
        try dbWriter.write { db in
            _ = try LevelRecord.deleteAll(db, keys: ids)
        }
    }

    func deleteAllLevels() throws {
        try dbWriter.write { db in
            _ = try LevelRecord.deleteAll(db)
        }
    }
}

// MARK: - Database Access: Reads

extension AppDatabase {
    func levelsOrderedByNamePublisher() -> AnyPublisher<[LevelRecord], Error> {
        ValueObservation
            .tracking(LevelRecord.all().orderedByName().fetchAll)
            .publisher(in: dbWriter, scheduling: .immediate)
            .eraseToAnyPublisher()
    }

    func fetchPegs(_ level: LevelRecord) throws -> [PegRecord] {
        try dbWriter.read(level.pegs.fetchAll)
    }

    func fetchBlocks(_ level: LevelRecord) throws -> [BlockRecord] {
        try dbWriter.read(level.blocks.fetchAll)
    }
}
