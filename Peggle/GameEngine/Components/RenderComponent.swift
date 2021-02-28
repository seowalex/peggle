import SwiftUI

final class RenderComponent: Component {
    var position: CGPoint
    var rotation: CGFloat
    var size: CGSize

    var state: State
    var imageName: String {
        imageNames[state] ?? ""
    }
    var imageNames: [State: String]
    var opacity: Double
    let transition: AnyTransition
    let zIndex: Double

    init(position: CGPoint, size: CGSize, imageNames: [State: String], rotation: CGFloat = 0.0, state: State = .base,
         opacity: Double = 1.0, transition: AnyTransition = .identity, zIndex: Double = 0) {
        self.position = position
        self.rotation = rotation
        self.size = size

        self.state = state
        self.imageNames = imageNames
        self.opacity = opacity
        self.transition = transition
        self.zIndex = zIndex
    }

    convenience init(position: CGPoint, size: CGSize, imageName: String, rotation: CGFloat = 0.0, opacity: Double = 1.0,
                     transition: AnyTransition = .identity, zIndex: Double = 0) {
        self.init(position: position,
                  size: size,
                  imageNames: [.base: imageName],
                  rotation: rotation,
                  opacity: opacity,
                  transition: transition,
                  zIndex: zIndex)
    }
}

extension RenderComponent {
    struct State: OptionSet {
        let rawValue: Int

        static let base = State()
        static let lit = State(rawValue: 1 << 0)
        static let loaded = State(rawValue: 1 << 1)
    }
}

extension RenderComponent.State: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension RenderComponent: Hashable {
    static func == (lhs: RenderComponent, rhs: RenderComponent) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
