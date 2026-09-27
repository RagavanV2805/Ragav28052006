import Foundation
import SwiftData

/// Single-row model describing the learner. The onboarding assessment is
/// stored here so the recommendation engine can reason about time budget,
/// target timeline and confidence.
@Model
final class UserProfile {
    var name: String
    var experienceLevelRaw: String
    var knownLanguages: [String]
    /// Completed projects before onboarding (free-form count).
    var completedProjectsCount: Int
    var dsaLevel: Int
    var csFundamentalsLevel: Int
    var dailyMinutes: Int
    var targetRoleSlug: String?
    var targetDate: Date?
    var confidenceLevel: Int
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \NotificationPreference.profile)
    var notificationPreference: NotificationPreference?

    init(
        name: String = "",
        experienceLevel: ExperienceLevel = .student,
        knownLanguages: [String] = [],
        completedProjectsCount: Int = 0,
        dsaLevel: Int = 0,
        csFundamentalsLevel: Int = 0,
        dailyMinutes: Int = 60,
        targetRoleSlug: String? = nil,
        targetDate: Date? = nil,
        confidenceLevel: Int = 2
    ) {
        self.name = name
        self.experienceLevelRaw = experienceLevel.rawValue
        self.knownLanguages = knownLanguages
        self.completedProjectsCount = completedProjectsCount
        self.dsaLevel = dsaLevel
        self.csFundamentalsLevel = csFundamentalsLevel
        self.dailyMinutes = dailyMinutes
        self.targetRoleSlug = targetRoleSlug
        self.targetDate = targetDate
        self.confidenceLevel = confidenceLevel
        self.hasCompletedOnboarding = false
        self.createdAt = .now
    }

    var experienceLevel: ExperienceLevel {
        get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .student }
        set { experienceLevelRaw = newValue.rawValue }
    }
}

/// Notification configuration, owned by the profile.
@Model
final class NotificationPreference {
    var dailyReminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var deadlineRemindersEnabled: Bool
    var weeklySummaryEnabled: Bool
    var inactivityReminderEnabled: Bool
    var authorizationRequested: Bool
    var profile: UserProfile?

    init() {
        self.dailyReminderEnabled = true
        self.reminderHour = 19
        self.reminderMinute = 0
        self.deadlineRemindersEnabled = true
        self.weeklySummaryEnabled = true
        self.inactivityReminderEnabled = true
        self.authorizationRequested = false
    }

    var reminderComponents: DateComponents {
        DateComponents(hour: reminderHour, minute: reminderMinute)
    }
}
