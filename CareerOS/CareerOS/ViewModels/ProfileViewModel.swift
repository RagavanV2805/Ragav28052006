import Foundation
import SwiftData
import Observation

@Observable
final class ProfileViewModel {
    /// Applies preference edits back to the model + scheduler.
    func savePreferences(_ preference: NotificationPreference, context: ModelContext) {
        try? context.save()
        guard !UITestMode.isActive else { return }
        let snapshot = preference
        Task {
            await NotificationService.shared.apply(snapshot)
        }
    }

    func updateDailyMinutes(_ minutes: Int, context: ModelContext) {
        let profile = PersistenceService.profile(in: context)
        profile.dailyMinutes = max(10, minutes)
        try? context.save()
    }

    func updateTimeline(months: Int, context: ModelContext) {
        let profile = PersistenceService.profile(in: context)
        profile.targetDate = Calendar.current.date(byAdding: .month, value: months, to: .now)
        try? context.save()
    }

    func updateName(_ name: String, context: ModelContext) {
        let profile = PersistenceService.profile(in: context)
        profile.name = name
        try? context.save()
    }

    func setTargetRole(slug: String, context: ModelContext) {
        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = slug
        try? context.save()
        WidgetSnapshotPublisher.publish(context: context)
    }

    func resetProgress(context: ModelContext) {
        SeedService.resetUserProgress(in: context)
        Task { await NotificationService.shared.cancelAll() }
        WidgetSnapshotPublisher.publish(context: context)
    }
}
