final class PowerComponent: Component {
    let power: Power
    var isActivated = false

    init(power: Power) {
        self.power = power
    }
}

extension PowerComponent {
    enum Power {
        case spaceBlast, spookyBall
    }
}
