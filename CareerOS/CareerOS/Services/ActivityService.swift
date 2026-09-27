import Foundation
import SwiftData

/// Reads learning activity (sessions + completions) and shapes it for
/// streaks, the dashboard and analytics charts.
struct ActivityService {
    let context: ModelContext

    private let streakCalculator = StreakCalculator()

    // MARK: - Basic facts

    func allSessions() -> [LearningSession] {
        PersistenceService.fetchAll(LearningSession.self, in: context)
    }

    /// Every day with any learning evidence: sessions, skill completions or
    /// project completions.
    func activeDays() -> Set<Date> {
        let calendar = Calendar.current
        var days = Set(allSessions().map { calendar.startOfDay(for: $0.day) })
        for progress in PersistenceService.fetchAll(SkillProgress.self, in: context) {
            if let date = progress.completedAt { days.insert(calendar.startOfDay(for: date)) }
            if let date = progress.startedAt { days.insert(calendar.startOfDay(for: date)) }
        }
        for progress in PersistenceService.fetchAll(ProjectProgress.self, in: context) {
            if let date = progress.completedAt { days.insert(calendar.startOfDay(for: date)) }
        }
        return days
    }

    func lastActivityDay() -> Date? {
        activeDays().max()
    }

    func currentStreak() -> (length: Int, atRisk: Bool) {
        streakCalculator.streak(activeDays: activeDays())
    }

    func totalMinutes() -> Int {
        allSessions().reduce(0) { $0 + $1.minutes }
    }

    // MARK: - Chart shapes

    struct DayActivity: Identifiable {
        let date: Date
        let minutes: Int
        var id: Date { date }
    }

    /// Minutes per day for the trailing window (always full-length).
    func dailyActivity(days: Int, endingOn reference: Date = .now) -> [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: reference)
        let minutesByDay = Dictionary(
            allSessions().map { (calendar.startOfDay(for: $0.day), $0.minutes) },
            uniquingKeysWith: +
        )
        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayActivity(date: date, minutes: minutesByDay[date] ?? 0)
        }
    }

    struct CumulativePoint: Identifiable {
        let date: Date
        let completedSkills: Int
        var id: Date { date }
    }

    /// Cumulative completed skills over the last `weeks` weeks.
    func progressOverTime(weeks: Int, endingOn reference: Date = .now) -> [CumulativePoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: reference)
        let completions = PersistenceService.fetchAll(SkillProgress.self, in: context)
            .compactMap(\.completedAt)
            .map { calendar.startOfDay(for: $0) }
            .sorted()

        let baseline = completions.filter {
            guard let start = calendar.date(byAdding: .weekOfYear, value: -weeks, to: today) else { return false }
            return $0 < start
        }.count

        var points: [CumulativePoint] = []
        for offset in stride(from: weeks, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -offset, to: today) else { continue }
            let count = completions.filter { $0 <= date }.count
            points.append(CumulativePoint(date: date, completedSkills: count))
        }
        _ = baseline // retained for future "since start" variants
        return points
    }

    struct CategorySlice: Identifiable {
        let category: SkillCategory
        let completed: Int
        let total: Int
        var fraction: Double { total > 0 ? Double(completed) / Double(total) : 0 }
        var id: String { category.rawValue }
    }

    /// Completion by skill category for a role's required nodes.
    func categoryBreakdown(for role: CareerRole) -> [CategorySlice] {
        let levels = RoadmapService(context: context).userLevels()
        let completed = RoadmapService(context: context).completedSkillSlugs()

        var buckets: [SkillCategory: (done: Int, total: Int)] = [:]
        for node in role.requiredNodes {
            guard let skill = node.skill else { continue }
            var bucket = buckets[skill.category] ?? (0, 0)
            bucket.total += 1
            let met = completed.contains(skill.slug) || (levels[skill.slug] ?? 0) >= node.targetLevel
            if met { bucket.done += 1 }
            buckets[skill.category] = bucket
        }

        return buckets
            .map { CategorySlice(category: $0.key, completed: $0.value.done, total: $0.value.total) }
            .sorted { $0.fraction > $1.fraction }
    }

    /// Skills completed most recently — for "recently completed" surfaces.
    func recentlyCompletedSkills(limit: Int = 5) -> [Skill] {
        PersistenceService.fetchAll(SkillProgress.self, in: context)
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(limit)
            .compactMap(\.skill)
    }
}
