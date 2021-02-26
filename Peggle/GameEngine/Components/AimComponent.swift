import CoreGraphics

final class AimComponent: Component {
    let position: CGPoint
    let initialAngle: CGFloat
    let minAngle: CGFloat
    let maxAngle: CGFloat

    var target: CGPoint?
    var velocity: CGVector?

    init(position: CGPoint, initialAngle: CGFloat, minAngle: CGFloat = -.pi, maxAngle: CGFloat = .pi) {
        self.position = position
        self.initialAngle = initialAngle
        self.minAngle = minAngle
        self.maxAngle = maxAngle
    }
}
