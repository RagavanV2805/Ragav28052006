import SwiftUI
import SwiftData

@main
struct CareerOSApp: App {
    private let container: ModelContainer

    init() {
        container = PersistenceService.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.accentColor)
        }
        .modelContainer(container)
    }
}
