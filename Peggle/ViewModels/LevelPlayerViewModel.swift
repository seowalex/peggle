import Combine
import SwiftUI

final class LevelPlayerViewModel: ObservableObject {
    @Published private(set) var name = ""
    @Published private(set) var gameState = StateComponent()
    @Published private(set) var components: [RenderComponent] = []

    @Published var alertIsPresented = false
    @Published private(set) var alertTitle = ""
    @Published private(set) var alertMessage = ""

    private let gameEngine: GameEngine
    private let gameRenderer: GameRenderer
    private var gameStateCancellable: AnyCancellable?
    private var renderCancellable: AnyCancellable?

    init(level: Level) {
        name = level.name
        gameEngine = GameEngine(elements: level.elements)
        gameRenderer = GameRenderer(gameEngine: gameEngine)

        gameStateCancellable = gameRenderer.gameStatePublisher.sink { [weak self] gameState in
            self?.gameState = gameState

            if case .ended(let state) = gameState.status {
                self?.gameRenderer.invalidateDisplayLink()

                switch state {
                case .won:
                    self?.alertTitle = "You Won!"
                case .lost:
                    self?.alertTitle = "You Lost..."
                }

                self?.alertMessage = "Score: \(gameState.score)"
                self?.alertIsPresented = true
            }
        }

        renderCancellable = gameRenderer.renderPublisher.sink { [weak self] components in
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
