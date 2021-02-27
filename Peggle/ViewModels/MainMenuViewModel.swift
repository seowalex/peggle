import SwiftUI

final class MainMenuViewModel: ObservableObject {
    let levelSelectViewModel: LevelSelectViewModel
    let levelEditorViewModel: LevelEditorViewModel

    init(database: AppDatabase) {
        levelSelectViewModel = LevelSelectViewModel(database: database)
        levelEditorViewModel = LevelEditorViewModel(database: database)
    }
}
