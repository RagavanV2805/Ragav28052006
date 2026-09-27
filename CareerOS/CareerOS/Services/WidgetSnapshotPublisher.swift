import Foundation
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Builds and publishes the widget snapshot whenever app state changes.
/// Views and view models call `publish(after:)` at the end of mutations.
enum WidgetSnapshotPublisher {

    static func publish(context: ModelContext) {
        let snapshot = build(context: context)
        WidgetSnapshotStore.save(snapshot)
        reloadTimelines()
    }

    static func reloadTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func build(context: ModelContext) -> WidgetSnapshot {
        let roadmapService = RoadmapService(context: context)
        let activityService = ActivityService(context: context)

        guard let role = roadmapService.targetRole() else {
            return WidgetSnapshot(
                targetRoleName: "No goal set",
                overallPercent: 0,
                nextSkillName: nil,
                nextSkillReason: nil,
                streakDays: activityService.currentStreak().length,
                todayItems: [],
                updatedAt: .now
            )
        }

        let summary = roadmapService.progressSummary(for: role)
        let plan = roadmapService.learningPlan(for: role)

        return WidgetSnapshot(
            targetRoleName: role.name,
            overallPercent: summary.overallPercent,
            nextSkillName: plan.primary?.skill.name ?? plan.blockerSuggestions.first?.skill.name,
            nextSkillReason: plan.primary?.reasons.first ?? plan.blockerSuggestions.first?.reasons.first,
            streakDays: activityService.currentStreak().length,
            todayItems: todayItems(for: role, roadmapService: roadmapService),
            updatedAt: .now
        )
    }

    /// Up to three roadmap items for the medium widget: one completed (if
    /// any recently), the current focus and what's coming next.
    private static func todayItems(
        for role: CareerRole,
        roadmapService: RoadmapService
    ) -> [WidgetSnapshot.TodayItem] {
        let levels = roadmapService.userLevels()
        let completed = roadmapService.completedSkillSlugs()

        let states: [(title: String, met: Bool, inProgress: Bool)] = role.orderedNodes
            .filter { !$0.isOptional }
            .compactMap { node in
                node.skill.map { skill in
                    let met = completed.contains(skill.slug) || (levels[skill.slug] ?? 0) >= node.targetLevel
                    let inProgress = roadmapService.nodeState(for: skill, in: role) == .inProgress
                    return (skill.name, met, inProgress)
                }
            }

        var items: [WidgetSnapshot.TodayItem] = []
        if let lastDone = states.last(where: \.met) {
            items.append(.init(title: lastDone.title, state: .done))
        }
        if let current = states.first(where: { !$0.met }) {
            items.append(.init(title: current.title, state: .current))
        }
        for upcoming in states.filter({ !$0.met }).dropFirst().prefix(2) {
            items.append(.init(title: upcoming.title, state: .upcoming))
        }
        return Array(items.prefix(3))
    }
}
