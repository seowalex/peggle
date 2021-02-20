import Combine
import SwiftUI

final class GameRenderer {
    var publisher: AnyPublisher<[RenderComponent], Never> {
        subject.eraseToAnyPublisher()
    }

    private let gameEngine: GameEngine
    private let subject = PassthroughSubject<[RenderComponent], Never>()

    private var displayLink: CADisplayLink!
    private var lag: CFTimeInterval = 0.0
    private let preferredFramesPerSecond: Double = 60

    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine

        displayLink = CADisplayLink(target: self, selector: #selector(render))
        displayLink.preferredFramesPerSecond = Int(preferredFramesPerSecond)
        displayLink.add(to: .main, forMode: .default)
    }

    @objc func render(displayLink: CADisplayLink) {
        lag += displayLink.targetTimestamp - displayLink.timestamp

        while lag >= 1 / preferredFramesPerSecond {
            gameEngine.update(deltaTime: CGFloat(1 / preferredFramesPerSecond))
            lag -= 1 / preferredFramesPerSecond
        }

        subject.send(gameEngine.getRenderComponents())
    }

    func invalidateDisplayLink() {
        displayLink.invalidate()
    }
}
