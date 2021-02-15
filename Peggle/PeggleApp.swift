import SwiftUI

@main
struct PeggleApp: App {
    let appDatabase = AppDatabase.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                LevelEditorView(viewModel: LevelEditorViewModel(database: appDatabase))
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
