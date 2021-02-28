import SwiftUI

@main
struct PeggleApp: App {
    @StateObject var settings = GameSettings()

    let appDatabase = AppDatabase.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainMenuView(viewModel: MainMenuViewModel(database: appDatabase))
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .accentColor(.init(red: 1, green: 0.75, blue: 0))
            .environmentObject(settings)
        }
    }

    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
            .tintColor = .init(red: 1, green: 0.75, blue: 0, alpha: 1)
    }
}
