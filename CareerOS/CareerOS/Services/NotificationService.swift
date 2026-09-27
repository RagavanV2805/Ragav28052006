import Foundation
import UserNotifications

/// Wraps UNUserNotificationCenter. All scheduling flows through here so
/// identifiers stay consistent and toggling preferences is deterministic.
actor NotificationService {
    static let shared = NotificationService()

    enum Identifier {
        static let dailyReminder = "careeros.reminder.daily"
        static let weeklySummary = "careeros.reminder.weekly"
        static let inactivity = "careeros.reminder.inactivity"
        static func deadline(projectSlug: String) -> String {
            "careeros.reminder.deadline.\(projectSlug)"
        }
    }

    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        }
    }

    /// Applies the user's full preference set: cancels what's off, schedules
    /// what's on. Safe to call after any preference change.
    func apply(_ preference: NotificationPreference) async {
        guard await requestAuthorizationIfNeeded() else {
            await cancelAll()
            return
        }

        if preference.dailyReminderEnabled {
            await scheduleDailyReminder(components: preference.reminderComponents)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyReminder])
        }

        if preference.weeklySummaryEnabled {
            await scheduleWeeklySummary()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklySummary])
        }

        if !preference.deadlineRemindersEnabled {
            let pending = await center.pendingNotificationRequests()
            let deadlineIDs = pending.map(\.identifier).filter { $0.hasPrefix("careeros.reminder.deadline.") }
            center.removePendingNotificationRequests(withIdentifiers: deadlineIDs)
        }
    }

    func scheduleDailyReminder(components: DateComponents) async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyReminder])
        let content = UNMutableNotificationContent()
        content.title = "Time to level up"
        content.body = "A focused session today keeps your roadmap moving. Open CareerOS to see what's next."
        content.sound = .default
        var repeating = components
        repeating.calendar = Calendar.current
        let trigger = UNCalendarNotificationTrigger(dateMatching: repeating, repeats: true)
        let request = UNNotificationRequest(identifier: Identifier.dailyReminder, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleWeeklySummary() async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklySummary])
        let content = UNMutableNotificationContent()
        content.title = "Your weekly progress summary"
        content.body = "See how many skills and projects you moved forward this week."
        content.sound = .default
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Identifier.weeklySummary, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// One reminder the evening after two inactive days.
    func scheduleInactivityReminderIfNeeded(lastActiveDay: Date?, preference: NotificationPreference) async {
        guard preference.inactivityReminderEnabled else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let inactive: Bool
        if let last = lastActiveDay {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: today).day ?? 0
            inactive = days >= 2
        } else {
            inactive = false
        }

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.inactivity])
        guard inactive else { return }

        let content = UNMutableNotificationContent()
        content.title = "We miss you 👋"
        content.body = "You haven't logged learning recently. Even 15 minutes keeps the streak alive."
        content.sound = .default
        var components = DateComponents()
        components.hour = 19
        components.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Identifier.inactivity, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Reminder ~24h before a project deadline.
    func scheduleDeadlineReminder(projectSlug: String, title: String, deadline: Date?) async {
        let identifier = Identifier.deadline(projectSlug: projectSlug)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let deadline, await requestAuthorizationIfNeeded() else { return }

        let fireDate = deadline.addingTimeInterval(-24 * 60 * 60)
        guard fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Project deadline tomorrow"
        content.body = "\"\(title)\" is due soon. Check your milestones to stay on track."
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelDeadlineReminder(projectSlug: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: [Identifier.deadline(projectSlug: projectSlug)]
        )
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}
