import CoreGraphics

final class OscillateComponent: Component {
    let amplitude: CGVector
    let position: CGPoint
    let angularFrequency: CGFloat
    let phaseShift: CGFloat
    var time: CGFloat = 0.0

    init(position: CGPoint, startPoint: CGPoint, endPoint: CGPoint, frequency: CGFloat) {
        self.amplitude = (endPoint - startPoint) / 2
        self.position = startPoint + amplitude
        self.angularFrequency = 2 * CGFloat.pi * frequency
        self.phaseShift = CGFloat.pi * position.distance(to: endPoint) / startPoint.distance(to: endPoint)
    }
}
