import SwiftUI

final class LevelEditorViewModel: ObservableObject {
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
        case (.delete, _):
            selectedElement = nil
            return nil
        case (_, .first):
            return nil
        case (_, .second(let dragValue)):
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)
            let translation = dragValue.translation.applying(normalize)
            var newPosition = element.position
            var isValid = true

            newPosition.x += translation.width
            newPosition.y += translation.height

            let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
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
        case (.delete, _):
            selectedElement = nil
            elements.removeAll(where: { $0 === element })
        case (_, .first):
            selectedElement = element
            element.isOscillating.toggle()
            objectWillChange.send()
        case (_, .second(let dragValue)):
            let normalize = CGAffineTransform(scaleX: 1 / frame.maxX, y: 1 / frame.maxY)
            let translation = dragValue.translation.applying(normalize)
            var newPosition = element.position

            newPosition.x += translation.width
            newPosition.y += translation.height

            let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
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

    func onResize(position: CGPoint, element: Element, direction: Direction) -> DragState? {
        let distanceVector = position.rotate(around: element.position, by: -element.rotation) - element.position
        var distance = CGFloat.zero
        var size = CGSize.zero
        var isValid = true

        switch direction {
        case .top, .bottom:
            distance = abs(distanceVector.dy) * 2
            size = CGSize(width: element is Peg ? distance : element.size.width, height: distance)
        case .left, .right:
            distance = abs(distanceVector.dx) * 2
            size = CGSize(width: distance, height: element is Peg ? distance : element.size.height)
        }

        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: size,
                                      position: element.position,
                                      rotation: element.rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
            isValid = false
        }

        return LevelEditorViewModel.DragState(element: element,
                                              position: element.position,
                                              rotation: element.rotation,
                                              size: size,
                                              isValid: isValid)
    }

    func onResizeEnd(position: CGPoint, element: Element, direction: Direction) {
        let distanceVector = position.rotate(around: element.position, by: -element.rotation) - element.position
        var distance = CGFloat.zero
        var size = CGSize.zero

        switch direction {
        case .top, .bottom:
            distance = abs(distanceVector.dy) * 2
            size = CGSize(width: element is Peg ? distance : element.size.width, height: distance)
        case .left, .right:
            distance = abs(distanceVector.dx) * 2
            size = CGSize(width: distance, height: element is Peg ? distance : element.size.height)
        }

        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: size,
                                      position: element.position,
                                      rotation: element.rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
            return
        }

        element.size = size
    }

    func onRotate(position: CGPoint, element: Element) -> DragState? {
        let normalizedPosition = position.rotate(around: element.position,
                                                 by: CGFloat.pi / 2)
        let rotation = element.position.angle(to: normalizedPosition)
        var isValid = true

        let physicsBody = PhysicsBody(shape: element.physicsBody.shape,
                                      size: element.size,
                                      position: element.position,
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
                                      size: element.size,
                                      position: element.position,
                                      rotation: rotation)

        if !frame.contains(physicsBody.boundingBox)
            || physicsBody.isColliding(with: elements.filter({ $0 !== element }).map { $0.physicsBody }) {
            return
        }

        element.rotation = rotation
    }

    func onOscillateMin(position: CGPoint, element: Element) {
        element.minCoefficient = (position.rotate(around: element.position, by: -element.rotation)
                                    - element.position).dx / element.size.width

        if element.minCoefficient < 0 {
            element.maxCoefficient = abs(element.maxCoefficient)
        } else if element.minCoefficient > 0 {
            element.maxCoefficient = -abs(element.maxCoefficient)
        }

        objectWillChange.send()
    }

    func onOscillateMax(position: CGPoint, element: Element) {
        element.maxCoefficient = (position.rotate(around: element.position, by: -element.rotation)
                                    - element.position).dx / element.size.width

        if element.maxCoefficient < 0 {
            element.minCoefficient = abs(element.minCoefficient)
        } else if element.maxCoefficient > 0 {
            element.minCoefficient = -abs(element.minCoefficient)
        }

        objectWillChange.send()
    }
}

// MARK: - Level Management

extension LevelEditorViewModel {
    func saveLevel() throws {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            throw ValidationError.missingName
        }

        if try database.isPreloadedLevel(name: name) == true {
            throw ValidationError.cannotOverride
        }

        var level = LevelRecord(name: name)
        var pegs = self.elements.compactMap { $0 as? Peg }.map { PegRecord(position: $0.position,
                                                                           rotation: $0.rotation,
                                                                           size: $0.size,
                                                                           isOscillating: $0.isOscillating,
                                                                           minCoefficient: $0.minCoefficient,
                                                                           maxCoefficient: $0.maxCoefficient,
                                                                           frequency: $0.frequency,
                                                                           color: $0.color)
        }
        var blocks = self.elements.compactMap { $0 as? Block }.map { BlockRecord(position: $0.position,
                                                                                 rotation: $0.rotation,
                                                                                 size: $0.size,
                                                                                 isOscillating: $0.isOscillating,
                                                                                 minCoefficient: $0.minCoefficient,
                                                                                 maxCoefficient: $0.maxCoefficient,
                                                                                 frequency: $0.frequency)
        }

        try database.saveLevel(&level, pegs: &pegs, blocks: &blocks)
    }

    func fetchLevel(_ level: LevelRecord) throws {
        selectedElement = nil

        name = level.name
        elements = try database.fetchPegs(level).map { Peg(position: $0.position,
                                                           color: $0.color,
                                                           rotation: $0.rotation,
                                                           size: $0.size,
                                                           isOscillating: $0.isOscillating,
                                                           minCoefficient: $0.minCoefficient,
                                                           maxCoefficient: $0.maxCoefficient,
                                                           frequency: $0.frequency)
        }
            + database.fetchBlocks(level).map { Block(position: $0.position,
                                                      rotation: $0.rotation,
                                                      size: $0.size,
                                                      isOscillating: $0.isOscillating,
                                                      minCoefficient: $0.minCoefficient,
                                                      maxCoefficient: $0.maxCoefficient,
                                                      frequency: $0.frequency)
            }
    }

    func reset() {
        name = ""
        elements.removeAll()
        selectedElement = nil
    }
}

extension LevelEditorViewModel {
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

    enum Direction {
        case top, bottom, left, right
    }

    private enum ValidationError: LocalizedError {
        case missingName, cannotOverride

        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Level name empty"
            case .cannotOverride:
                return "Preloaded levels cannot be overriden"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .missingName:
                return "Please give a name to this level"
            case .cannotOverride:
                return "Try saving the level as a new level"
            }
        }
    }
}
