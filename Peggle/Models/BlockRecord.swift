import CoreGraphics
import GRDB

// Position and size are normalised to a maximum of 1
struct BlockRecord: Equatable {
    // Ensure ID is a 64-bit signed integer even on 32-bit platforms
    // See https://sqlite.org/lang_createtable.html#rowid
    var id: Int64?
    var levelId: Int64?
    var position: CGPoint
    var rotation: CGFloat = 0.0
    var size: CGSize = Block.defaultSize
}

// MARK: - Persistence

extension BlockRecord: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let levelId = Column(CodingKeys.levelId)
        static let position = Column(CodingKeys.position)
        static let rotation = Column(CodingKeys.rotation)
        static let size = Column(CodingKeys.size)
    }

    static let databaseTableName = "block"

    // Updates a block ID after it has been inserted in the database
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
