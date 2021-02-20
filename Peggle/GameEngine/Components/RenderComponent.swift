import SwiftUI

final class RenderComponent: Component {
    var position: CGPoint
    var rotation: CGFloat
    var size: CGSize

    var state: State
    var imageName: String
    let imageNames: [State: String]
    let transition: AnyTransition
    let zIndex: Double

    private init(position: CGPoint, size: CGSize, imageName: String, imageNames: [State: String],
                 rotation: CGFloat = 0.0, state: State = .base, transition: AnyTransition = .identity,
                 zIndex: Double = 0) {
        self.position = position
        self.rotation = rotation
        self.size = size

        self.state = state
        self.imageName = imageName
        self.imageNames = imageNames
        self.transition = transition
        self.zIndex = zIndex
    }

    convenience init(position: CGPoint, size: CGSize, imageName: String, rotation: CGFloat = 0.0,
                     transition: AnyTransition = .identity, zIndex: Double = 0) {
        self.init(position: position,
                  size: size,
                  imageName: imageName,
                  imageNames: [.base: imageName],
                  rotation: rotation,
                  transition: transition,
                  zIndex: zIndex)
    }

    convenience init(position: CGPoint, size: CGSize, imageNames: [State: String], rotation: CGFloat = 0.0,
                     state: State = .base, transition: AnyTransition = .identity, zIndex: Double = 0) {
        self.init(position: position,
                  size: size,
                  imageName: imageNames[state] ?? "",
                  imageNames: imageNames,
                  rotation: rotation,
                  state: state,
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
