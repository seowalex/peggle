import CoreGraphics

final class TargetComponent: Component {
    let position: CGPoint
    let initialAngle: CGFloat
    let minAngle: CGFloat
    let maxAngle: CGFloat

    var target: CGPoint?

    init(position: CGPoint, initialAngle: CGFloat, minAngle: CGFloat = -.pi, maxAngle: CGFloat = .pi) {
        self.position = position
        self.initialAngle = initialAngle
        self.minAngle = minAngle
        self.maxAngle = maxAngle
    }
}
