import Foundation
import SwiftData
import Observation

struct AnalyticsData {
    let overallPercent: Int
    let skillsCompleted: Int
    let projectsCompleted: Int
    let streakLength: Int
    let totalMinutes: Int
    let weeklyActivity: [ActivityService.DayActivity]
    let progressOverTime: [ActivityService.CumulativePoint]
    let categoryBreakdown: [ActivityService.CategorySlice]
}

@Observable
final class AnalyticsViewModel {
    private(set) var state: ViewState<AnalyticsData> = .loading

    func load(context: ModelContext) async {
        state = .loading
        let service = RoadmapService(context: context)
        let activity = ActivityService(context: context)

        guard let role = service.targetRole() else {
            // No goal yet — analytics still show activity where available.
            let data = AnalyticsData(
                overallPercent: 0,
                skillsCompleted: PersistenceService.fetchAll(SkillProgress.self, in: context).filter { $0.status == .completed }.count,
                projectsCompleted: PersistenceService.fetchAll(ProjectProgress.self, in: context).filter { $0.status == .completed }.count,
                streakLength: activity.currentStreak().length,
                totalMinutes: activity.totalMinutes(),
                weeklyActivity: activity.dailyActivity(days: 7),
                progressOverTime: activity.progressOverTime(weeks: 12),
                categoryBreakdown: []
            )
            state = .loaded(data)
            return
        }

        let summary = service.progressSummary(for: role)
        let data = AnalyticsData(
            overallPercent: summary.overallPercent,
            skillsCompleted: PersistenceService.fetchAll(SkillProgress.self, in: context).filter { $0.status == .completed }.count,
            projectsCompleted: PersistenceService.fetchAll(ProjectProgress.self, in: context).filter { $0.status == .completed }.count,
            streakLength: activity.currentStreak().length,
            totalMinutes: activity.totalMinutes(),
            weeklyActivity: activity.dailyActivity(days: 7),
            progressOverTime: activity.progressOverTime(weeks: 12),
            categoryBreakdown: activity.categoryBreakdown(for: role)
        )
        state = .loaded(data)
    }

    var formattedTotalTime: String {
        guard case .loaded(let data) = state else { return "0h" }
        let hours = data.totalMinutes / 60
        let minutes = data.totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        return "\(hours)h \(minutes)m"
    }
}
