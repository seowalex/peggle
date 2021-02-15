import GRDB

struct Level: Identifiable, Equatable {
    // Ensure ID is a 64-bit signed integer even on 32-bit platforms
    // See https://sqlite.org/lang_createtable.html#rowid
    var id: Int64?
    var name: String
}

extension Level {
    private static let names = [
        "Asteroid Blues", "Stray Dog Strut", "Honky Tonk Women", "Gateway Shuffle", "Ballad of Fallen Angels",
        "Sympathy for the Devil", "Heavy Metal Queen", "Waltz for Venus", "Jamming with Edward", "Ganymede Elegy",
        "Toys in the Attic", "Jupiter Jazz", "Bohemian Rhapsody", "My Funny Valentine", "Black Dog Serenade",
        "Mushroom Samba", "Speak Like a Child", "Wild Horses", "Pierrot le Fou", "Boogie Woogie Feng Shui",
        "Cowboy Funk", "Brain Scratch", "Hard Luck Woman", "The Real Folk Blues"
    ]

    static func new() -> Self {
        Level(name: "")
    }

    static func newRandom() -> Self {
        let name = names.randomElement() ?? ""

        return Level(name: name)
    }
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
