import CoreGraphics
import GRDB

// Position and size are normalised to a maximum of 1
struct PegRecord: Equatable {
    static let defaultSize = CGSize(width: 0.04, height: 0.04)

    // Ensure ID is a 64-bit signed integer even on 32-bit platforms
    // See https://sqlite.org/lang_createtable.html#rowid
    var id: Int64?
    var levelId: Int64?
    var position: CGPoint
    var rotation: CGFloat = 0.0
    var size: CGSize = defaultSize
    var color: Color
}

extension PegRecord {
    var imageName: String {
        switch color {
        case .blue:
            return "peg-blue"
        case .orange:
            return "peg-orange"
        case .green:
            return "peg-green"
        case .purple:
            return "peg-purple"
        }
    }
}

extension PegRecord {
    enum Color: String, Codable, CaseIterable {
        case blue, orange, green, purple
    }
}

// MARK: - Persistence

extension PegRecord: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let levelId = Column(CodingKeys.levelId)
        static let position = Column(CodingKeys.position)
        static let rotation = Column(CodingKeys.rotation)
        static let size = Column(CodingKeys.size)
        static let color = Column(CodingKeys.color)
    }

    static let databaseTableName = "peg"

    // Updates a peg ID after it has been inserted in the database
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
