import Foundation
import SwiftData
@testable import CareerOS

/// Shared helpers for SwiftData-backed tests.
enum TestStore {
    /// Fresh, seeded, in-memory container per test run.
    static func makeContainer() throws -> ModelContainer {
        try PersistenceService.makeInMemoryContainer(seeded: true)
    }
}
