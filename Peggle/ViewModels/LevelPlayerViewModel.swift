import Combine
import SwiftUI

final class LevelPlayerViewModel: ObservableObject {
    @Published private(set) var name = ""
    @Published private(set) var components: [RenderComponent] = []

    private let gameEngine: GameEngine
    private let gameRenderer: GameRenderer
    private var cancellable: AnyCancellable?

    init(level: Level) {
        name = level.name
        gameEngine = GameEngine(elements: level.elements)
        gameRenderer = GameRenderer(gameEngine: gameEngine)

        cancellable = gameRenderer.publisher.sink { [weak self] components in
            self?.components = components
        }
    }

    func onDrag(position: CGPoint) {
        gameEngine.onDrag(position: position)
    }

    func onDragEnd(position: CGPoint) {
        gameEngine.onDragEnd(position: position)
    }

    deinit {
        gameRenderer.invalidateDisplayLink()
    }
}
