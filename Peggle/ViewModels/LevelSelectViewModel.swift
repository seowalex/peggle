import Combine
import GRDB
import SwiftUI

final class LevelSelectViewModel: ObservableObject {
    @Published private(set) var levels: [Level] = []

    private let database: AppDatabase
    private var levelsCancellable: AnyCancellable?

    init(database: AppDatabase) {
        self.database = database
        levelsCancellable = levelsPublisher(in: database)
            .sink { [weak self] levels in
                self?.levels = levels.compactMap {
                    guard let elements = try? self?.fetchLevel($0) else {
                        return nil
                    }

                    return Level(name: $0.name, elements: elements)
                }
            }
    }

    func fetchLevel(_ level: LevelRecord) throws -> [Element] {
        try database.fetchPegs(level).map { Peg(position: $0.position,
                                                color: $0.color,
                                                rotation: $0.rotation,
                                                size: $0.size,
                                                isOscillating: $0.isOscillating,
                                                minCoefficient: $0.minCoefficient,
                                                maxCoefficient: $0.maxCoefficient,
                                                frequency: $0.frequency)
        }
            + database.fetchBlocks(level).map { Block(position: $0.position,
                                                      rotation: $0.rotation,
                                                      size: $0.size,
                                                      isOscillating: $0.isOscillating,
                                                      minCoefficient: $0.minCoefficient,
                                                      maxCoefficient: $0.maxCoefficient,
                                                      frequency: $0.frequency)
            }
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
