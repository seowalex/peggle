import GRDB

struct Level: Identifiable, Equatable {
    // Ensure ID is a 64-bit signed integer even on 32-bit platforms
    // See https://sqlite.org/lang_createtable.html#rowid
    var id: Int64?
    var name: String
}

// MARK: - Persistence

extension Level: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }

    static let pegs = hasMany(Peg.self)
    var pegs: QueryInterfaceRequest<Peg> {
        request(for: Level.pegs)
    }

    // Updates a level ID after it has been inserted in the database
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Player Database Requests

extension DerivableRequest where RowDecoder == Level {
    func orderedByName() -> Self {
        order(Level.Columns.name)
    }
}
