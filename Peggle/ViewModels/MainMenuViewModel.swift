import Combine
import CoreGraphics

final class MainMenuViewModel: ObservableObject {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    func createLevelEditorViewModel() -> LevelEditorViewModel {
        LevelEditorViewModel(database: database)
    }
}
