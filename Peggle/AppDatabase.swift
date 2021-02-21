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
                    .check { $0 >= 0 && $0 < 2 * Double.pi }
                t.column("size", .text)
                    .notNull()
                t.column("color", .text)
                    .notNull()
                    .check { PegRecord.Color.allCases.map { $0.rawValue }.contains($0) }
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
    func saveLevel(_ level: inout LevelRecord, pegs: inout [PegRecord]) throws {
        try dbWriter.write { db in
            try level.save(db)

            guard pegs.compactMap({ $0.levelId }).allSatisfy({ $0 == level.id }) else {
                throw DatabaseError(message: "Pegs do not have the correct level ID")
            }

            let bodies = pegs.map { PhysicsBody(shape: .circle, size: $0.size, position: $0.position) }

            guard bodies.allSatisfy({ !$0.isColliding(with: bodies) }) else {
                throw DatabaseError(message: "Pegs are colliding with each other")
            }

            // Delete pegs that are not in the peg array
            try level.pegs.filter(!pegs.compactMap { $0.id }.contains(PegRecord.Columns.id)).deleteAll(db)

            for index in pegs.indices {
                pegs[index].levelId = pegs[index].levelId ?? level.id
                try pegs[index].save(db)
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
}
