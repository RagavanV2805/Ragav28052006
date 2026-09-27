import Foundation
import SwiftData

/// The user's state for one skill. Keyed by the skill slug so progress
/// survives role changes (historical progress is never lost when the user
/// switches target role).
@Model
final class SkillProgress {
    /// Mirrors `Skill.slug`; unique per user store.
    @Attribute(.unique) var skillSlug: String
    /// Self rating 0...5.
    var level: Int
    var statusRaw: String
    var startedAt: Date?
    var completedAt: Date?
    var personalNotes: String
    var skill: Skill?

    init(skillSlug: String, level: Int = 0, status: SkillStatus = .notStarted) {
        self.skillSlug = skillSlug
        self.level = level
        self.statusRaw = status.rawValue
        self.personalNotes = ""
    }

    var status: SkillStatus {
        get { SkillStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var levelEnum: SkillLevel {
        get { SkillLevel(clamping: level) }
        set { level = newValue.rawValue }
    }

    /// A skill counts as *satisfied* when it is completed or rated at a solid
    /// working level (intermediate or above).
    var isSatisfied: Bool {
        status == .completed || level >= SkillLevel.intermediate.rawValue
    }
}

/// The user's state for one project (status, deadline, notes). Percentage is
/// derived from milestones — see `Project.milestoneFraction`.
@Model
final class ProjectProgress {
    @Attribute(.unique) var projectSlug: String
    var statusRaw: String
    var deadline: Date?
    var notes: String
    var startedAt: Date?
    var completedAt: Date?
    var project: Project?

    init(projectSlug: String, status: ProjectStatus = .notStarted) {
        self.projectSlug = projectSlug
        self.statusRaw = status.rawValue
        self.notes = ""
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }
}

/// One logged block of learning time. Powers streaks, weekly activity and
/// time-spent analytics.
@Model
final class LearningSession {
    var day: Date
    var minutes: Int
    var skillSlug: String?
    var loggedAt: Date

    init(day: Date, minutes: Int, skillSlug: String? = nil) {
        self.day = Calendar.current.startOfDay(for: day)
        self.minutes = minutes
        self.skillSlug = skillSlug
        self.loggedAt = .now
    }
}
