import CoreGraphics
import Foundation

final class ClearComponent: Component {
    let speed: CGFloat
    var timer: Timer?
    var willClear = false

    init(speed: CGFloat) {
        self.speed = speed
    }
}
