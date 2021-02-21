import SwiftUI

final class LevelEditorViewModel: ObservableObject {
    struct DragState {
        let element: Element
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
        guard case .addPeg(let color) = paletteSelection else {
            selectedElement = nil
            return nil
        }

        let placeholderPeg = Peg(position: position, color: color)
        var isValid = true

        if !frame.contains(placeholderPeg.physicsBody.boundingBox)
            || placeholderPeg.physicsBody.isColliding(with: pegs.map { $0.physicsBody }) {
            isValid = false
        }

        selectedElement = placeholderPeg

        return DragState(element: placeholderPeg, position: position, rotation: placeholderPeg.rotation,
                         size: placeholderPeg.size, isValid: isValid)
    }

    func onDragEnd(position: CGPoint) {
        guard case .addPeg(let color) = paletteSelection else {
            selectedElement = nil
            return
        }

        let placeholderPeg = Peg(position: position, color: color)

        if !frame.contains(placeholderPeg.physicsBody.boundingBox)
            || placeholderPeg.physicsBody.isColliding(with: pegs.map { $0.physicsBody }) {
            selectedElement = nil
            return
        }

        selectedElement = placeholderPeg
        pegs.append(placeholderPeg)
    }

    func onDrag(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value, peg: Peg, frame: CGRect) -> DragState? {
        guard case .addPeg = paletteSelection, case .second(let dragValue) = value else {
            selectedElement = nil
            return nil
        }

        let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)
        let translation = dragValue.translation.applying(normalize)
        var newPosition = peg.position
        var isValid = true

        newPosition.x += translation.width
        newPosition.y += translation.height

        let physicsBody = PhysicsBody(shape: .circle, size: peg.size, position: newPosition)

        if !self.frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter({ $0 !== peg }).map { $0.physicsBody }) {
            isValid = false
        }

        selectedElement = peg

        return DragState(element: peg, position: newPosition, rotation: peg.rotation, size: peg.size, isValid: isValid)
    }

    func onDragEnd(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value, peg: Peg, frame: CGRect) {
        switch (paletteSelection, value) {
        case (.deletePeg, _), (.addPeg, .first):
            selectedElement = nil
            pegs.removeAll(where: { $0 === peg })
        case (.addPeg, .second(let dragValue)):
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)
            let translation = dragValue.translation.applying(normalize)
            var newPosition = peg.position
            newPosition.x += translation.width
            newPosition.y += translation.height

            let physicsBody = PhysicsBody(shape: .circle, size: peg.size, position: newPosition)

            if !self.frame.contains(physicsBody.boundingBox)
                || physicsBody.isColliding(with: pegs.filter({ $0 !== peg }).map { $0.physicsBody }) {
                return
            }

            selectedElement = peg
            peg.position = newPosition
        }
    }

    func onResize(length: CGFloat, element: Element) -> DragState? {
        var isValid = true

        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: CGSize(width: length, height: length),
                                      position: element.physicsBody.position)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter({ $0 !== element }).map { $0.physicsBody }) {
            isValid = false
        }

        return LevelEditorViewModel.DragState(element: element,
                                              position: element.position,
                                              rotation: element.rotation,
                                              size: CGSize(width: length, height: length),
                                              isValid: isValid)
    }

    func onResizeEnd(length: CGFloat, element: Element) {
        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: CGSize(width: length, height: length),
                                      position: element.physicsBody.position)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter({ $0 !== element }).map { $0.physicsBody }) {
            return
        }

        element.size = CGSize(width: length, height: length)
    }

    func onRotate(position: CGPoint, element: Element) -> DragState? {
        let normalizedPosition = position.rotate(around: element.position,
                                                 by: CGFloat.pi / 2)
        let rotation = element.position.angle(to: normalizedPosition)
        var isValid = true

        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: element.physicsBody.size,
                                      position: element.physicsBody.position,
                                      rotation: rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter({ $0 !== element }).map { $0.physicsBody }) {
            isValid = false
        }

        return LevelEditorViewModel.DragState(element: element,
                                              position: element.position,
                                              rotation: rotation,
                                              size: element.size,
                                              isValid: isValid)
    }

    func onRotateEnd(position: CGPoint, element: Element) {
        let normalizedPosition = position.rotate(around: element.position,
                                                 by: CGFloat.pi / 2)
        let rotation = element.position.angle(to: normalizedPosition)
        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: element.physicsBody.size,
                                      position: element.physicsBody.position,
                                      rotation: rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: pegs.filter({ $0 !== element }).map { $0.physicsBody }) {
            return
        }

        element.rotation = rotation
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
        selectedElement = nil
    }
}
