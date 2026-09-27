import Foundation
import SwiftData
import Observation

/// Everything the dashboard presents, pre-shaped. A plain value type so the
/// view can render it without further fetching.
struct DashboardData {
    struct Deadline: Identifiable {
        let project: Project
        let deadline: Date
        var id: String { project.slug }
    }

    struct ActiveProject {
        let project: Project
        let fraction: Double
    }

    let targetRole: CareerRole?
    let progressSummary: RoadmapProgressSummary?
    let plan: LearningPlan?
    let streakLength: Int
    let streakAtRisk: Bool
    let weeklyActivity: [ActivityService.DayActivity]
    let currentProject: ActiveProject?
    let upcomingDeadlines: [Deadline]
    let recentlyCompleted: [Skill]
    let skillsCompleted: Int
    let skillsInProgress: Int
}

@Observable
final class DashboardViewModel {
    private(set) var state: ViewState<DashboardData> = .loading

    /// Loads and shapes all dashboard facts. Cheap local reads only.
    func load(context: ModelContext) async {
        state = .loading
        do {
            try await Task.sleep(nanoseconds: 60_000_000) // let first frame draw
            let data = buildData(context: context)
            state = .loaded(data)
        } catch {
            state = .failed("Couldn't load your dashboard.")
        }
    }

    func refresh(context: ModelContext) {
        guard case .loaded = state else { return }
        state = .loaded(buildData(context: context))
    }

    private func buildData(context: ModelContext) -> DashboardData {
        let roadmapService = RoadmapService(context: context)
        let activityService = ActivityService(context: context)
        let role = roadmapService.targetRole()

        let summary = role.map { roadmapService.progressSummary(for: $0) }
        let plan = role.map { roadmapService.learningPlan(for: $0) }

        // Current project: most recently started, non-completed.
        let progressRecords = PersistenceService.fetchAll(ProjectProgress.self, in: context)
            .filter { $0.status == .inProgress || $0.status == .paused }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }
        var currentProject: DashboardData.ActiveProject?
        if let record = progressRecords.first, let project = record.project {
            currentProject = DashboardData.ActiveProject(project: project, fraction: project.milestoneFraction)
        }

        // Deadlines within 14 days for active projects.
        let soon = Date.now.addingTimeInterval(14 * 24 * 3600)
        let deadlines = PersistenceService.fetchAll(ProjectProgress.self, in: context)
            .filter { $0.status == .inProgress || $0.status == .paused }
            .compactMap { record -> DashboardData.Deadline? in
                guard let deadline = record.deadline, deadline <= soon, let project = record.project else { return nil }
                return DashboardData.Deadline(project: project, deadline: deadline)
            }
            .sorted { $0.deadline < $1.deadline }

        let progress = PersistenceService.fetchAll(SkillProgress.self, in: context)
        let streak = activityService.currentStreak()

        return DashboardData(
            targetRole: role,
            progressSummary: summary,
            plan: plan,
            streakLength: streak.length,
            streakAtRisk: streak.atRisk,
            weeklyActivity: activityService.dailyActivity(days: 7),
            currentProject: currentProject,
            upcomingDeadlines: deadlines,
            recentlyCompleted: activityService.recentlyCompletedSkills(limit: 4),
            skillsCompleted: progress.filter { $0.status == .completed }.count,
            skillsInProgress: progress.filter { $0.status == .inProgress }.count
        )
    }

    // MARK: - Actions

    /// Starts the recommended skill straight from the dashboard.
    func startRecommended(_ recommendation: SkillRecommendation, context: ModelContext) {
        let progress = PersistenceService.skillProgress(forSkillSlug: recommendation.skill.id, in: context)
        if progress.status == .notStarted {
            progress.status = .inProgress
            progress.startedAt = .now
        }
        PersistenceService.logLearningSession(minutes: 15, skillSlug: recommendation.skill.id, in: context)
        try? context.save()
        refresh(context: context)
        WidgetSnapshotPublisher.publish(context: context)
    }
}
