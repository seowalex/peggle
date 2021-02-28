final class StateComponent: Component {
    let orangePegsCount: Int
    var orangePegsRemainingCount: Int = 0
    var score: Int = 0

    init(orangePegsCount: Int = 0) {
        self.orangePegsCount = orangePegsCount
    }
}
