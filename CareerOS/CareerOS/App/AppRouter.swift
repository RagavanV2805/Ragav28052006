import SwiftUI
import Observation

enum AppTab: Hashable, CaseIterable {
    case home
    case roadmap
    case projects
    case analytics
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .roadmap: return "Roadmap"
        case .projects: return "Projects"
        case .analytics: return "Analytics"
        case .profile: return "Profile"
        }
    }

    var symbolName: String {
        switch self {
        case .home: return "house.fill"
        case .roadmap: return "map.fill"
        case .projects: return "hammer.fill"
        case .analytics: return "chart.bar.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

/// Owns tab selection and per-tab navigation paths.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home

    var homePath = NavigationPath()
    var roadmapPath = NavigationPath()
    var projectsPath = NavigationPath()
    var analyticsPath = NavigationPath()
    var profilePath = NavigationPath()

    /// Pop a tab to its root.
    func popToRoot(_ tab: AppTab) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .roadmap: roadmapPath = NavigationPath()
        case .projects: projectsPath = NavigationPath()
        case .analytics: analyticsPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    /// Jump to another tab and optionally reset its stack.
    func switchTo(_ tab: AppTab) {
        selectedTab = tab
    }

    /// Deep-link helper used after onboarding and by the dashboard.
    func openSkill(_ skill: Skill) {
        selectedTab = .roadmap
        roadmapPath = NavigationPath()
        roadmapPath.append(skill)
    }

    func openProject(_ project: Project) {
        selectedTab = .projects
        projectsPath = NavigationPath()
        projectsPath.append(project)
    }
}

/// Shared destination registrations so every tab stack can push the same
/// detail screens.
struct CareerDestinationsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Skill.self) { skill in
                SkillDetailView(skill: skill)
            }
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .navigationDestination(for: CareerRole.self) { role in
                RoleDetailView(role: role)
            }
    }
}

extension View {
    func careerDestinations() -> some View {
        modifier(CareerDestinationsModifier())
    }
}
