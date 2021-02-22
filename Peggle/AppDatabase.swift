import Combine
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

        return migrator
    }

    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
}

// MARK: - Database Access: Writes

extension AppDatabase {
    func saveLevel(_ level: inout LevelRecord, pegs: inout [PegRecord], blocks: inout [BlockRecord]) throws {
        try dbWriter.write { db in
            level = try LevelRecord.filter(LevelRecord.Columns.name == level.name).fetchOne(db) ?? level
            try level.save(db)
            try level.pegs.deleteAll(db)
            try level.blocks.deleteAll(db)

            let bodies = pegs.map { PhysicsBody(shape: .circle,
                                                size: $0.size,
                                                position: $0.position,
                                                rotation: $0.rotation)
            }
                + blocks.map { PhysicsBody(shape: .rectangle,
                                           size: $0.size,
                                           position: $0.position,
                                           rotation: $0.rotation)
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
