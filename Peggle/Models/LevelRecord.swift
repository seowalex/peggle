import GRDB

struct LevelRecord: Identifiable, Equatable {
    // Ensure ID is a 64-bit signed integer even on 32-bit platforms
    // See https://sqlite.org/lang_createtable.html#rowid
    var id: Int64?
    var name: String
}

// MARK: - Persistence

extension LevelRecord: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }

    static let databaseTableName = "level"
    static let pegs = hasMany(PegRecord.self)
    var pegs: QueryInterfaceRequest<PegRecord> {
        request(for: LevelRecord.pegs)
    }

    // Updates a level ID after it has been inserted in the database
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Player Database Requests

extension DerivableRequest where RowDecoder == LevelRecord {
    func orderedByName() -> Self {
        order(LevelRecord.Columns.name)
    }
}
