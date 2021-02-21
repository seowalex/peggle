import Combine
import CoreGraphics

final class LevelPlayerViewModel: ObservableObject {
    @Published private(set) var components: [RenderComponent] = []

    private let gameEngine: GameEngine
    private let gameRenderer: GameRenderer
    private var cancellable: AnyCancellable?

    init(pegs: [PegRecord]) {
        gameEngine = GameEngine(pegs: pegs.map { peg in
            var peg = peg
            peg.position = peg.position.applying(CGAffineTransform(translationX: 0, y: 0.4))

            return peg
        })
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
