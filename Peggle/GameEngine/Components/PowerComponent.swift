final class PowerComponent: Component {
    let power: Power
    var isActivated = false
    var hasBeenActivated = false

    init(power: Power) {
        self.power = power
    }
}

extension PowerComponent {
    enum Power {
        case spaceBlast, spookyBall
    }
}
