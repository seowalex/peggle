import SwiftUI

final class LevelEditorViewModel: ObservableObject {
    struct DragState {
        let peg: PegRecord
        let location: CGPoint
        let isValid: Bool
    }

    enum PaletteSelection: Equatable {
        case addPeg(PegRecord.Color)
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
    @Published private(set) var pegs: [PegRecord] = []
    @Published var level = LevelRecord(name: "")
    @Published var paletteSelection = PaletteSelection.addPeg(.blue)

    let levelEditorListViewModel: LevelEditorListViewModel

    private let frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
        levelEditorListViewModel = LevelEditorListViewModel(database: database)
    }

    func onDrag(position: CGPoint) -> DragState? {
        guard case .addPeg(let color) = paletteSelection else {
            return nil
        }

        let physicsBody = PhysicsBody(shape: .circle, size: PegRecord.defaultSize, position: position)
        var isValid = true

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.map { PhysicsBody(shape: .circle,
                                                                    size: $0.size,
                                                                    position: $0.position)
            }) {
            isValid = false
        }

        return DragState(peg: PegRecord(position: position, color: color), location: position, isValid: isValid)
    }

    func onDragEnd(position: CGPoint) {
        guard case .addPeg(let color) = paletteSelection else {
            return
        }

        let physicsBody = PhysicsBody(shape: .circle, size: PegRecord.defaultSize, position: position)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.map { PhysicsBody(shape: .circle,
                                                                    size: $0.size,
                                                                    position: $0.position)
            }) {
            return
        }

        pegs.append(PegRecord(position: position, color: color))
    }

    func onDrag(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value,
                peg: PegRecord, normalize: CGAffineTransform) -> DragState? {
        guard case .addPeg = paletteSelection, case .second(let dragValue) = value else {
            return nil
        }

        let translation = dragValue.translation.applying(normalize)
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

    func onDragEnd(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value,
                   peg: PegRecord, normalize: CGAffineTransform) {
        guard let index = pegs.firstIndex(where: { $0 == peg }) else {
            return
        }

        switch (paletteSelection, value) {
        case (.deletePeg, _), (.addPeg, .first):
            pegs.remove(at: index)
        case (.addPeg, .second(let dragValue)):
            let translation = dragValue.translation.applying(normalize)
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
        level = LevelRecord(name: "")
    }
}
