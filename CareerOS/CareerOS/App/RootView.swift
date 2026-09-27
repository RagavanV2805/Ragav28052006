import SwiftUI
import SwiftData

/// Root switch: onboarding until it's completed, then the main tab
/// application. Onboarding is deliberately *not* part of tab navigation.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @State private var router = AppRouter()

    private var onboardingComplete: Bool {
        profiles.first?.hasCompletedOnboarding ?? false
    }

    var body: some View {
        Group {
            if onboardingComplete {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingComplete)
        .environment(router)
        .task {
            // Guarantee a profile row exists before anything reads it.
            _ = PersistenceService.profile(in: context)
            await refreshInactivityReminder()
        }
    }

    private func refreshInactivityReminder() async {
        guard !UITestMode.isActive else { return }
        guard let profile = profiles.first, let preference = profile.notificationPreference else { return }
        let lastActive = ActivityService(context: context).lastActivityDay()
        await NotificationService.shared.scheduleInactivityReminderIfNeeded(
            lastActiveDay: lastActive,
            preference: preference
        )
    }
}

/// The five-tab application shell.
struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            HomeTab()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.symbolName) }
                .tag(AppTab.home)

            RoadmapTab()
                .tabItem { Label(AppTab.roadmap.title, systemImage: AppTab.roadmap.symbolName) }
                .tag(AppTab.roadmap)

            ProjectsTab()
                .tabItem { Label(AppTab.projects.title, systemImage: AppTab.projects.symbolName) }
                .tag(AppTab.projects)

            AnalyticsTab()
                .tabItem { Label(AppTab.analytics.title, systemImage: AppTab.analytics.symbolName) }
                .tag(AppTab.analytics)

            ProfileTab()
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.symbolName) }
                .tag(AppTab.profile)
        }
    }
}

// MARK: - Tab wrappers (one NavigationStack per tab)

struct HomeTab: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.homePath) {
            DashboardView()
                .careerDestinations()
        }
    }
}

struct RoadmapTab: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.roadmapPath) {
            RoadmapView()
                .careerDestinations()
        }
    }
}

struct ProjectsTab: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.projectsPath) {
            ProjectsListView()
                .careerDestinations()
        }
    }
}

struct AnalyticsTab: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.analyticsPath) {
            AnalyticsView()
                .careerDestinations()
        }
    }
}

struct ProfileTab: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.profilePath) {
            ProfileView()
                .careerDestinations()
        }
    }
}
