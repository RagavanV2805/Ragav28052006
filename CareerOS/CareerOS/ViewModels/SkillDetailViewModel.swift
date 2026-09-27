import Foundation
import SwiftData
import Observation

/// Handles all mutations for a skill detail screen. Display-only facts are
/// read straight off the model by the view; anything that changes state goes
/// through here.
@Observable
final class SkillDetailViewModel {
    let skill: Skill

    private(set) var progress: SkillProgress?
    private(set) var importance: Int?
    private(set) var targetLevel: Int?
    private(set) var state: RoadmapService.NodeState = .available
    private(set) var suggestedProjects: [Project] = []

    init(skill: Skill) {
        self.skill = skill
    }

    func load(context: ModelContext) {
        let service = RoadmapService(context: context)
        progress = PersistenceService.skillProgress(forSkillSlug: skill.slug, in: context)

        // Importance/target come from the current target role when the skill
        // is part of it.
        if let role = service.targetRole(),
           let node = role.orderedNodes.first(where: { $0.skill?.slug == skill.slug }) {
            importance = node.importance
            targetLevel = node.targetLevel
        } else {
            importance = nil
            targetLevel = nil
        }
        state = service.nodeState(for: skill)

        suggestedProjects = suggestedProjects(for: context)
    }

    private func suggestedProjects(for context: ModelContext) -> [Project] {
        // Projects requiring this skill, prioritised by eligibility.
        let satisfied = RoadmapService(context: context).satisfiedSkillSlugs()
        let calculator = ProjectEligibilityCalculator()
        return skill.projectsRequiring
            .sorted { lhs, rhs in
                calculator.readiness(requiredSkillIDs: lhs.requiredSkills.map(\.slug), satisfiedIDs: satisfied)
                    > calculator.readiness(requiredSkillIDs: rhs.requiredSkills.map(\.slug), satisfiedIDs: satisfied)
            }
    }

    // MARK: - Mutations

    func updateLevel(_ level: Int, context: ModelContext) {
        guard let progress else { return }
        progress.level = level
        if level >= SkillLevel.intermediate.rawValue, progress.status == .notStarted {
            progress.status = .completed
            progress.completedAt = .now
        }
        try? context.save()
        afterMutation(context: context)
    }

    func start(context: ModelContext) {
        guard let progress else { return }
        if progress.status == .notStarted {
            progress.status = .inProgress
            progress.startedAt = .now
        }
        try? context.save()
        afterMutation(context: context)
    }

    func markComplete(context: ModelContext) {
        guard let progress else { return }
        progress.status = .completed
        progress.completedAt = .now
        if let target = targetLevel, progress.level < target {
            progress.level = target
        } else if progress.level == 0 {
            progress.level = SkillLevel.intermediate.rawValue
        }
        PersistenceService.logLearningSession(minutes: 30, skillSlug: skill.slug, in: context)
        try? context.save()
        afterMutation(context: context)
    }

    func reopen(context: ModelContext) {
        guard let progress else { return }
        progress.status = .inProgress
        progress.completedAt = nil
        try? context.save()
        afterMutation(context: context)
    }

    func saveNotes(_ notes: String, context: ModelContext) {
        progress?.personalNotes = notes
        try? context.save()
    }

    func logSession(minutes: Int, context: ModelContext) {
        guard minutes > 0 else { return }
        PersistenceService.logLearningSession(minutes: minutes, skillSlug: skill.slug, in: context)
        try? context.save()
        afterMutation(context: context)
    }

    private func afterMutation(context: ModelContext) {
        load(context: context)
        WidgetSnapshotPublisher.publish(context: context)
    }
}
