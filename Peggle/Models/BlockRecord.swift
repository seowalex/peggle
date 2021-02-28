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
    var isOscillating: Bool = false
    var minCoefficient: CGFloat = -1.0
    var maxCoefficient: CGFloat = 1.0
    var frequency: CGFloat = 0.2
}

// MARK: - Persistence

extension BlockRecord: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let levelId = Column(CodingKeys.levelId)
        static let position = Column(CodingKeys.position)
        static let rotation = Column(CodingKeys.rotation)
        static let size = Column(CodingKeys.size)
        static let isOscillating = Column(CodingKeys.isOscillating)
        static let minCoefficient = Column(CodingKeys.minCoefficient)
        static let maxCoefficient = Column(CodingKeys.maxCoefficient)
        static let frequency = Column(CodingKeys.frequency)
    }

    static let databaseTableName = "block"

    // Updates a block ID after it has been inserted in the database
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
