import SwiftUI

final class LevelEditorViewModel: ObservableObject {
    struct DragState {
        let peg: Peg
        let position: CGPoint
        let rotation: CGFloat
        let size: CGSize
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
    @Published var paletteSelection = PaletteSelection.addPeg(.blue)
    @Published var selectedElement: Element?

    let levelEditorListViewModel: LevelEditorListViewModel

    private let frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
        levelEditorListViewModel = LevelEditorListViewModel(database: database)
    }

    func onDrag(position: CGPoint) -> DragState? {
        selectedElement = nil

        guard case .addPeg(let color) = paletteSelection else {
            return nil
        }

        let placeholderPeg = Peg(position: position, color: color)
        var isValid = true

        if !frame.contains(placeholderPeg.physicsBody.boundingBox)
            || placeholderPeg.physicsBody.isColliding(with: pegs.map { $0.physicsBody }) {
            isValid = false
        }

        return DragState(peg: placeholderPeg, position: position, rotation: placeholderPeg.rotation,
                         size: placeholderPeg.size, isValid: isValid)
    }

    func onDragEnd(position: CGPoint) {
        guard case .addPeg(let color) = paletteSelection else {
            return
        }

        let placeholderPeg = Peg(position: position, color: color)

        if !frame.contains(placeholderPeg.physicsBody.boundingBox)
            || placeholderPeg.physicsBody.isColliding(with: pegs.map { $0.physicsBody }) {
            return
        }

        selectedElement = placeholderPeg
        pegs.append(placeholderPeg)
    }

    func onDrag(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value,
                peg: Peg, normalize: CGAffineTransform) -> DragState? {
        selectedElement = nil

        guard case .addPeg = paletteSelection, case .second(let dragValue) = value else {
            return nil
        }

        let translation = dragValue.translation.applying(normalize)
        var newPosition = peg.position
        var isValid = true

        newPosition.x += translation.width
        newPosition.y += translation.height

        let physicsBody = PhysicsBody(shape: .circle, size: peg.size, position: newPosition)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter({ $0 !== peg }).map { $0.physicsBody }) {
            isValid = false
        }

        return DragState(peg: peg, position: newPosition, rotation: peg.rotation, size: peg.size, isValid: isValid)
    }

    func onDragEnd(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value,
                   peg: Peg, normalize: CGAffineTransform) {
        switch (paletteSelection, value) {
        case (.deletePeg, _), (.addPeg, .first):
            pegs.removeAll(where: { $0 === peg })
        case (.addPeg, .second(let dragValue)):
            selectedElement = peg

            let translation = dragValue.translation.applying(normalize)
            var newPosition = peg.position
            newPosition.x += translation.width
            newPosition.y += translation.height

            let physicsBody = PhysicsBody(shape: .circle, size: peg.size, position: newPosition)

            if !frame.contains(physicsBody.boundingBox)
                || physicsBody.isColliding(with: pegs.filter({ $0 !== peg }).map { $0.physicsBody }) {
                return
            }

            peg.position = newPosition
        }
    }

    // MARK: - Level Management

    func saveLevel() throws {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            throw ValidationError.missingName
        }

        var level = LevelRecord(name: name)
        var pegs = self.pegs.map { PegRecord(position: $0.position,
                                             rotation: $0.rotation,
                                             size: $0.size,
                                             color: $0.color)
        }

        try database.saveLevel(&level, pegs: &pegs)
    }

    func fetchLevel(_ level: LevelRecord) throws {
        name = level.name
        pegs = try database.fetchPegs(level).map { Peg(position: $0.position,
                                                       color: $0.color,
                                                       rotation: $0.rotation,
                                                       size: $0.size)
        }
    }

    func reset() {
        name = ""
        pegs.removeAll()
    }
}
