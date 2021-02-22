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
        case addBlock
        case delete
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
    @Published private(set) var elements: [Element] = []
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
        switch paletteSelection {
        case .addPeg(let color):
            let placeholderPeg = Peg(position: position, color: color)
            var isValid = true

            if !frame.contains(placeholderPeg.physicsBody.boundingBox)
                || placeholderPeg.physicsBody.isColliding(with: elements.map { $0.physicsBody }) {
                isValid = false
            }

            selectedElement = placeholderPeg

            return DragState(element: placeholderPeg, position: position, rotation: placeholderPeg.rotation,
                             size: placeholderPeg.size, isValid: isValid)
        case .addBlock:
            let placeholderBlock = Block(position: position)
            var isValid = true

            if !frame.contains(placeholderBlock.physicsBody.boundingBox)
                || placeholderBlock.physicsBody.isColliding(with: elements.map { $0.physicsBody }) {
                isValid = false
            }

            selectedElement = placeholderBlock

            return DragState(element: placeholderBlock, position: position, rotation: placeholderBlock.rotation,
                             size: placeholderBlock.size, isValid: isValid)
        case .delete:
            selectedElement = nil
            return nil
        }
    }

    func onDragEnd(position: CGPoint) {
        switch paletteSelection {
        case .addPeg(let color):
            let placeholderPeg = Peg(position: position, color: color)

            if !frame.contains(placeholderPeg.physicsBody.boundingBox)
                || placeholderPeg.physicsBody.isColliding(with: elements.map { $0.physicsBody }) {
                selectedElement = nil
                return
            }

            selectedElement = placeholderPeg
            elements.append(placeholderPeg)
        case .addBlock:
            let placeholderBlock = Block(position: position)

            if !frame.contains(placeholderBlock.physicsBody.boundingBox)
                || placeholderBlock.physicsBody.isColliding(with: elements.map { $0.physicsBody }) {
                selectedElement = nil
                return
            }

            selectedElement = placeholderBlock
            elements.append(placeholderBlock)
        case .delete:
            selectedElement = nil
            return
        }
    }

    func onDrag(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value,
                element: Element, frame: CGRect) -> DragState? {
        switch (paletteSelection, value) {
        case (.delete, _), (_, .first):
            selectedElement = nil
            return nil
        case (_, .second(let dragValue)):
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)
            let translation = dragValue.translation.applying(normalize)
            var newPosition = element.position
            var isValid = true

            newPosition.x += translation.width
            newPosition.y += translation.height

            var shape = PhysicsBody.Shape.rectangle

            if element is Peg {
                shape = .circle
            } else if element is Block {
                shape = .rectangle
            }

            let physicsBody = PhysicsBody(shape: shape,
                                          size: element.size,
                                          position: newPosition,
                                          rotation: element.rotation)

            if !self.frame.contains(physicsBody.boundingBox)
                || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
                isValid = false
            }

            selectedElement = element

            return DragState(element: element, position: newPosition, rotation: element.rotation, size: element.size,
                             isValid: isValid)
        }
    }

    func onDragEnd(value: ExclusiveGesture<LongPressGesture, DragGesture>.Value,
                   element: Element, frame: CGRect) {
        switch (paletteSelection, value) {
        case (.delete, _), (_, .first):
            selectedElement = nil
            elements.removeAll(where: { $0 === element })
        case (_, .second(let dragValue)):
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)
            let translation = dragValue.translation.applying(normalize)
            var newPosition = element.position
            newPosition.x += translation.width
            newPosition.y += translation.height

            var shape = PhysicsBody.Shape.rectangle

            if element is Peg {
                shape = .circle
            } else if element is Block {
                shape = .rectangle
            }

            let physicsBody = PhysicsBody(shape: shape,
                                          size: element.size,
                                          position: newPosition,
                                          rotation: element.rotation)

            if !self.frame.contains(physicsBody.boundingBox)
                || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
                return
            }

            selectedElement = element
            element.position = newPosition
        }
    }

    func onResize(width: CGFloat, height: CGFloat, element: Element) -> DragState? {
        var isValid = true

        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: CGSize(width: width, height: height),
                                      position: element.physicsBody.position,
                                      rotation: element.physicsBody.rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
            isValid = false
        }

        return LevelEditorViewModel.DragState(element: element,
                                              position: element.position,
                                              rotation: element.rotation,
                                              size: CGSize(width: width, height: height),
                                              isValid: isValid)
    }

    func onResizeEnd(width: CGFloat, height: CGFloat, element: Element) {
        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: CGSize(width: width, height: height),
                                      position: element.physicsBody.position,
                                      rotation: element.physicsBody.rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
            return
        }

        element.size = CGSize(width: width, height: height)
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
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
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
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
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
        var pegs = self.elements.compactMap { $0 as? Peg }.map { PegRecord(position: $0.position,
                                                                           rotation: $0.rotation,
                                                                           size: $0.size,
                                                                           color: $0.color )
        }
        var blocks = self.elements.compactMap { $0 as? Block }.map { BlockRecord(position: $0.position,
                                                                                 rotation: $0.rotation,
                                                                                 size: $0.size)
        }

        try database.saveLevel(&level, pegs: &pegs, blocks: &blocks)
    }

    func fetchLevel(_ level: LevelRecord) throws {
        name = level.name
        elements = try database.fetchPegs(level).map { Peg(position: $0.position,
                                                           color: $0.color,
                                                           rotation: $0.rotation,
                                                           size: $0.size)
        }
            + database.fetchBlocks(level).map { Block(position: $0.position,
                                                      rotation: $0.rotation,
                                                      size: $0.size)
            }
    }

    func reset() {
        name = ""
        elements.removeAll()
        selectedElement = nil
    }
}
