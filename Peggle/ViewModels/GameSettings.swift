import Combine

final class GameSettings: ObservableObject {
    @Published var power = PowerComponent.Power.spaceBlast
}
