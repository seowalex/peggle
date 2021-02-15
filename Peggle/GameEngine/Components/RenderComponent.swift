import SwiftUI

final class RenderComponent: Component {
    var position: CGPoint
    var rotation: CGFloat
    var size: CGSize

    var imageName: String
    let transition: AnyTransition
    let zIndex: Double

    init(position: CGPoint, size: CGSize, imageName: String, rotation: CGFloat = 0.0,
         transition: AnyTransition = .identity, zIndex: Double = 0) {
        self.position = position
        self.rotation = rotation
        self.size = size
        self.imageName = imageName
        self.transition = transition
        self.zIndex = zIndex
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
