import SwiftUI
import SwiftData

@main
struct CareerOSApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Role.self, Settings.self)
            SeedData.seedIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to create container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

/// Shows onboarding until a role is chosen, then the tabbed app.
struct ContentView: View {
    @Query private var settingsList: [Settings]

    var body: some View {
        if let settings = settingsList.first, settings.hasOnboarded {
            MainTabs()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { RoadmapView() }
                .tabItem { Label("Roadmap", systemImage: "map.fill") }
            NavigationStack { ProjectsView() }
                .tabItem { Label("Projects", systemImage: "hammer.fill") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
