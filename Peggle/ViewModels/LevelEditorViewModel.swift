import CoreGraphics
import Foundation

final class LevelEditorViewModel: ObservableObject {
    struct DragState {
        let peg: Peg
        let location: CGPoint
        let isValid: Bool
    }

    enum PaletteSelection: Equatable {
        case addPeg(Peg.Color)
        case deletePeg
    }

    private enum ValidationError: LocalizedError {
        case missingName

        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Level name empty"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .missingName:
                return "Please give a name to this level"
            }
        }
    }

    @Published var name = ""
    @Published private(set) var pegs: [Peg] = []
    @Published var level = Level(name: "")
    @Published var paletteSelection = PaletteSelection.addPeg(.blue)

    let levelEditorListViewModel: LevelEditorListViewModel

    private let frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
        levelEditorListViewModel = LevelEditorListViewModel(database: database)
    }

    func dragBoard(position: CGPoint) {
        guard case let .addPeg(color) = paletteSelection else {
            return
        }

        let physicsBody = PhysicsBody(shape: .circle, size: Peg.defaultSize, position: position)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.map { PhysicsBody(shape: .circle,
                                                                    size: $0.size,
                                                                    position: $0.position)
            }) {
            return
        }

        pegs.append(Peg(position: position, color: color))
    }

    func draggingBoard(position: CGPoint) -> DragState? {
        guard case let .addPeg(color) = paletteSelection else {
            return nil
        }

        let physicsBody = PhysicsBody(shape: .circle, size: Peg.defaultSize, position: position)
        var isValid = true

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.map { PhysicsBody(shape: .circle,
                                                                    size: $0.size,
                                                                    position: $0.position)
            }) {
            isValid = false
        }

        return DragState(peg: Peg(position: position, color: color), location: position, isValid: isValid)
    }

    func longPressPeg(peg: Peg) {
        guard let index = pegs.firstIndex(where: { $0 == peg }) else {
            return
        }

        pegs.remove(at: index)
    }

    func draggingPeg(peg: Peg, translation: CGSize) -> DragState? {
        if case .deletePeg = paletteSelection {
            return nil
        }

        var newLocation = peg.position
        var isValid = true

        newLocation.x += translation.width
        newLocation.y += translation.height

        let physicsBody = PhysicsBody(shape: .circle, size: peg.size, position: newLocation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter { $0 != peg }.map { PhysicsBody(shape: .circle,
                                                                                         size: $0.size,
                                                                                         position: $0.position)
            }) {
            isValid = false
        }

        return DragState(peg: peg, location: newLocation, isValid: isValid)
    }

    func dragPeg(peg: Peg, translation: CGSize) {
        guard let index = pegs.firstIndex(where: { $0 == peg }) else {
            return
        }

        switch paletteSelection {
        case .deletePeg:
            pegs.remove(at: index)
        case .addPeg:
            var newLocation = peg.position
            newLocation.x += translation.width
            newLocation.y += translation.height

            let physicsBody = PhysicsBody(shape: .circle, size: peg.size, position: newLocation)

            if !frame.contains(physicsBody.boundingBox)
                || physicsBody.isColliding(with: pegs.filter { $0 != peg }.map { PhysicsBody(shape: .circle,
                                                                                             size: $0.size,
                                                                                             position: $0.position)
                }) {
                return
            }

            pegs[index].position = newLocation
        }
    }

    // MARK: - Level Management

    func saveLevel() throws {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            throw ValidationError.missingName
        }

        // Save as a copy if the name is different
        // TODO: Warn if overriding
        if level.name != name {
            level.id = nil
            level.name = name

            for index in 0..<pegs.count {
                pegs[index].id = nil
                pegs[index].levelId = nil
            }
        }

        try database.saveLevel(&level, pegs: &pegs)
    }

    func fetchLevel() throws {
        name = level.name
        pegs = try database.fetchPegs(level)
    }

    func reset() {
        name = ""
        pegs.removeAll()
        level = Level(name: "")
    }
}
