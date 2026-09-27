import Foundation

/// Lightweight, `Codable` snapshot of everything the widgets need. The app
/// writes it to the shared App Group store whenever relevant state changes;
/// widget providers read it without touching SwiftData (which is owned by
/// the app process).
struct WidgetSnapshot: Codable, Equatable {
    struct TodayItem: Codable, Equatable {
        enum State: String, Codable { case done, current, upcoming }
        let title: String
        let state: State
    }

    var targetRoleName: String
    var overallPercent: Int
    var nextSkillName: String?
    var nextSkillReason: String?
    var streakDays: Int
    var todayItems: [TodayItem]
    var updatedAt: Date

    static let placeholder = WidgetSnapshot(
        targetRoleName: "No goal set",
        overallPercent: 0,
        nextSkillName: nil,
        nextSkillReason: nil,
        streakDays: 0,
        todayItems: [],
        updatedAt: .distantPast
    )
}

/// Read/write access to the snapshot in the App Group container.
enum WidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.careeros.shared"
    private static let key = "careeros.widget.snapshot.v1"

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func load() -> WidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroupIdentifier),
            let data = defaults.data(forKey: key)
        else { return .placeholder }
        return (try? JSONDecoder().decode(WidgetSnapshot.self, from: data)) ?? .placeholder
    }
}
