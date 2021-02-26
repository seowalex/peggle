import CoreGraphics

final class OscillateComponent: Component {
    let amplitude: CGVector
    let position: CGPoint
    let angularFrequency: CGFloat
    let phaseShift: CGFloat
    var time: CGFloat = 0.0

    init(position: CGPoint, startVector: CGVector, endVector: CGVector, frequency: CGFloat) {
        self.amplitude = (endVector - startVector) / 2
        self.position = position + startVector + amplitude
        self.angularFrequency = 2 * CGFloat.pi * frequency
        self.phaseShift = CGFloat.pi * endVector.magnitude() / (endVector - startVector).magnitude()
    }
}
