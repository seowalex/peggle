import Combine
import SwiftUI

final class LevelEditorListViewModel: ObservableObject {
    @Published private(set) var levels: [LevelRecord] = []

    private let database: AppDatabase
    private var levelsCancellable: AnyCancellable?

    init(database: AppDatabase) {
        self.database = database
        levelsCancellable = levelsPublisher(in: database)
            .sink { [weak self] levels in
                self?.levels = levels
            }
    }

    // MARK: - Levels List Management

    func deleteLevels(at offsets: IndexSet) throws {
        let levelIDs = offsets.compactMap { levels[$0].id }
        try database.deleteLevels(ids: levelIDs)
    }

    func deleteAllLevels() throws {
        try database.deleteAllLevels()
    }

    // MARK: - Private

    private func levelsPublisher(in database: AppDatabase) -> AnyPublisher<[LevelRecord], Never> {
        database.levelsOrderedByNamePublisher()
            .catch { _ in
                Just<[LevelRecord]>([])
            }
            .eraseToAnyPublisher()
    }
}
