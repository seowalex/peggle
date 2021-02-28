final class PowerComponent: Component {
    let power: Power
    var isActivated = false
    var turnsRemaining: Int

    init(power: Power) {
        self.power = power

        switch power {
        case .superGuide:
            self.turnsRemaining = 4
        case .spaceBlast, .spookyBall:
            self.turnsRemaining = 1
        }
    }
}

extension PowerComponent {
    enum Power: String, CaseIterable {
        case spaceBlast = "Space Blast"
        case spookyBall = "Spooky Ball"
        case superGuide = "Super Guide"
    }
}
