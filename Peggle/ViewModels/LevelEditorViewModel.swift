import CoreGraphics
import Foundation

final class LevelEditorViewModel: ObservableObject {
    struct DragState {
        let peg: Peg
        let location: CGPoint
        let isValid: Bool
    }

    enum PaletteSelection: Equatable {
        case addPeg(Peg.Shape, Peg.Color)
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
    @Published var level = Level.new()
    @Published var paletteSelection = PaletteSelection.addPeg(.circle, .blue)

    let levelEditorListViewModel: LevelEditorListViewModel

    private let frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
        levelEditorListViewModel = LevelEditorListViewModel(database: database)
    }

    func dragBoard(position: CGPoint) {
        guard case let .addPeg(shape, color) = paletteSelection else {
            return
        }

        let placeholderPeg = Peg(position: position, shape: shape, color: color)

        if placeholderPeg.isColliding(with: frame) || placeholderPeg.isColliding(with: pegs) {
            return
        }

        pegs.append(placeholderPeg)
    }

    func draggingBoard(position: CGPoint) -> DragState? {
        guard case let .addPeg(shape, color) = paletteSelection else {
            return nil
        }

        let placeholderPeg = Peg(position: position, shape: shape, color: color)
        var isValid = true

        if placeholderPeg.isColliding(with: frame) || placeholderPeg.isColliding(with: pegs) {
            isValid = false
        }

        return DragState(peg: placeholderPeg, location: position, isValid: isValid)
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

        let placeholderPeg = Peg(position: newLocation, size: peg.size, shape: peg.shape)

        if placeholderPeg.isColliding(with: frame) || placeholderPeg.isColliding(with: pegs.filter { $0 != peg }) {
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

            let placeholderPeg = Peg(position: newLocation, size: peg.size, shape: peg.shape)

            if placeholderPeg.isColliding(with: frame) || placeholderPeg.isColliding(with: pegs.filter { $0 != peg }) {
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
        level = .new()
    }
}
