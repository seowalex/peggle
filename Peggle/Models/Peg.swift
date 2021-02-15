import CoreGraphics
import GRDB

// Position and size are normalised to a maximum of 1
struct Peg: Equatable {
    static let defaultSize = CGSize(width: 0.04, height: 0.04)

    // Ensure ID is a 64-bit signed integer even on 32-bit platforms
    // See https://sqlite.org/lang_createtable.html#rowid
    var id: Int64?
    var levelId: Int64?
    var position: CGPoint
    var rotation: CGFloat = 0.0
    var size: CGSize = defaultSize
    var shape: Peg.Shape
    var color: Peg.Color?
}

extension Peg {
    enum Shape: String, Codable, CaseIterable {
        case circle, triangle
    }

    enum Color: String, Codable, CaseIterable {
        case blue, orange, green, purple
    }
}

extension Peg {
    static func newRandom() -> Self {
        let marginX = defaultSize.width / 2
        let marginY = defaultSize.height / 2

        return Peg(
            position: CGPoint(x: .random(in: (0 + marginX)...(1 - marginX)),
                              y: .random(in: (0 + marginY)...(1 - marginY))),
            // TODO: Keep it a circle (for now)
            shape: .circle,
            color: [.blue, .orange].randomElement()
        )
    }

    // TODO: Handle other shapes
    var imageName: String {
        switch (shape, color) {
        case (.circle, .blue):
            return "peg-blue"
        case (.circle, .orange):
            return "peg-orange"
        default:
            return ""
        }
    }
}

// MARK: - Collision Detection

extension Peg {
    func isColliding(with peg: Peg) -> Bool {
        let bodyA = PhysicsBody(shape: PhysicsBody.Shape(shape),
                                size: size,
                                position: position,
                                rotation: rotation)
        let bodyB = PhysicsBody(shape: PhysicsBody.Shape(shape),
                                size: peg.size,
                                position: peg.position,
                                rotation: peg.rotation)

        return bodyA.isColliding(with: bodyB)
    }

    func isColliding(with pegs: [Peg]) -> Bool {
        !pegs.allSatisfy { !isColliding(with: $0) }
    }

    func isColliding(with frame: CGRect) -> Bool {
        let physicsBody = PhysicsBody(shape: PhysicsBody.Shape(shape),
                                      size: size,
                                      position: position,
                                      rotation: rotation)

        return !frame.contains(physicsBody.boundingBox)
    }
}

// MARK: - Persistence

extension Peg: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let levelId = Column(CodingKeys.levelId)
        static let position = Column(CodingKeys.position)
        static let rotation = Column(CodingKeys.rotation)
        static let shape = Column(CodingKeys.shape)
        static let size = Column(CodingKeys.size)
        static let color = Column(CodingKeys.color)
    }

    // Updates a peg ID after it has been inserted in the database
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}
