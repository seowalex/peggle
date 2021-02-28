import CoreGraphics

final class ScoreComponent: Component {
    let color: Peg.Color
    var score: Int {
        switch color {
        case .blue, .green:
            return 10
        case .orange:
            return 100
        case .purple:
            return 500
        }
    }
    var multiplier: Int = 1
    var isHit: Bool = false
    var isScored: Bool = false

    init(color: Peg.Color) {
        self.color = color
    }
}
