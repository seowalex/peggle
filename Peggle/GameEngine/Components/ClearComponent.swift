import CoreGraphics
import Foundation

final class ClearComponent: Component {
    let speed: CGFloat
    var timer: Timer?

    init(speed: CGFloat) {
        self.speed = speed
    }
}
