import Foundation
import SwiftData
import Observation

/// Mutations for a single project: status, milestones, deadline, notes.
@Observable
final class ProjectDetailViewModel {
    let project: Project

    init(project: Project) {
        self.project = project
    }

    func progressRecord(context: ModelContext) -> ProjectProgress {
        PersistenceService.projectProgress(forProjectSlug: project.slug, in: context)
    }

    var fraction: Double { project.milestoneFraction }

    /// All required skills satisfied?
    func isEligible(context: ModelContext) -> Bool {
        let satisfied = RoadmapService(context: context).satisfiedSkillSlugs()
        return ProjectEligibilityCalculator().isEligible(
            requiredSkillIDs: project.requiredSkills.map(\.slug),
            satisfiedIDs: satisfied
        )
    }

    func satisfiedRequiredSkills(context: ModelContext) -> Set<String> {
        RoadmapService(context: context).satisfiedSkillSlugs()
    }

    // MARK: - Mutations

    func start(context: ModelContext) {
        let record = progressRecord(context: context)
        record.status = .inProgress
        record.startedAt = record.startedAt ?? .now
        try? context.save()
        WidgetSnapshotPublisher.publish(context: context)
    }

    func pause(context: ModelContext) {
        let record = progressRecord(context: context)
        record.status = .paused
        try? context.save()
    }

    func resume(context: ModelContext) {
        let record = progressRecord(context: context)
        record.status = .inProgress
        try? context.save()
    }

    func markCompleted(context: ModelContext) {
        let record = progressRecord(context: context)
        record.status = .completed
        record.completedAt = .now
        for milestone in project.milestones where !milestone.isDone {
            milestone.isDone = true
            milestone.completedAt = .now
        }
        PersistenceService.logLearningSession(minutes: 30, skillSlug: nil, in: context)
        try? context.save()
        WidgetSnapshotPublisher.publish(context: context)
    }

    func toggleMilestone(_ milestone: ProjectMilestone, context: ModelContext) {
        milestone.isDone.toggle()
        milestone.completedAt = milestone.isDone ? .now : nil
        let record = progressRecord(context: context)

        // Auto-status transitions derived from milestone state.
        if record.status == .notStarted {
            record.status = .inProgress
            record.startedAt = .now
        }
        if project.milestones.allSatisfy(\.isDone) {
            record.status = .completed
            record.completedAt = .now
        } else if record.status == .completed {
            record.status = .inProgress
            record.completedAt = nil
        }
        try? context.save()
        WidgetSnapshotPublisher.publish(context: context)
    }

    func setDeadline(_ deadline: Date?, context: ModelContext) {
        let record = progressRecord(context: context)
        record.deadline = deadline
        try? context.save()
        guard !UITestMode.isActive else { return }
        Task {
            await NotificationService.shared.scheduleDeadlineReminder(
                projectSlug: project.slug,
                title: project.title,
                deadline: deadline
            )
        }
    }

    func saveNotes(_ notes: String, context: ModelContext) {
        let record = progressRecord(context: context)
        record.notes = notes
        try? context.save()
    }
}
