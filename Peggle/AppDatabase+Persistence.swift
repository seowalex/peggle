import Foundation
import GRDB

extension AppDatabase {
    static let shared = makeShared()

    private static func makeShared() -> AppDatabase {
        do {
            let url = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("db.sqlite")
            let dbPool = try DatabasePool(path: url.path)
            let appDatabase = try AppDatabase(dbPool)

            return appDatabase
        } catch {
            // TODO: More robust error handling. Possible errors include:
            //
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            fatalError("Unresolved error \(error)")
        }
    }

    // Allow force tries since these functions are only used for previews
    // swiftlint:disable force_try
    static func empty() -> AppDatabase {
        let dbQueue = DatabaseQueue()

        return try! AppDatabase(dbQueue)
    }
    // swiftlint:enable force_try
}
