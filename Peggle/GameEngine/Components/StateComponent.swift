final class StateComponent: Component {
    let orangePegsCount: Int
    var orangePegsRemainingCount: Int = 0
    var score: Int = 0
    var ballsCount: Int = 1
    var status: Status = .playing

    init(orangePegsCount: Int = 0) {
        self.orangePegsCount = orangePegsCount
    }
}

extension StateComponent {
    enum Status {
        case playing, ended(State)
    }

    enum State {
        case won, lost
    }
}
