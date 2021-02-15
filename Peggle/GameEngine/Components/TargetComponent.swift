import CoreGraphics

final class TargetComponent: Component {
    let position: CGPoint
    let initialAngle: CGFloat
    let minAngle: CGFloat
    let maxAngle: CGFloat

    var target: CGPoint?
    var isTargeting = false

    let imageName: String
    let targetedImageName: String

    init(position: CGPoint, initialAngle: CGFloat, imageName: String, targetedImageName: String,
         minAngle: CGFloat = -.pi, maxAngle: CGFloat = .pi) {
        self.position = position
        self.initialAngle = initialAngle
        self.minAngle = minAngle
        self.maxAngle = maxAngle
        self.imageName = imageName
        self.targetedImageName = targetedImageName
    }
}
