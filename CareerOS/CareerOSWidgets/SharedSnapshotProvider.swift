import Foundation
import WidgetKit

/// Timeline provider shared by both widgets. Reads the snapshot published by
/// the app into the App Group store — widgets never touch SwiftData.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SharedSnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        let now = Date.now
        let entries = [0, 30, 90].compactMap { offset -> SnapshotEntry? in
            guard let date = Calendar.current.date(byAdding: .minute, value: offset, to: now) else { return nil }
            return SnapshotEntry(date: date, snapshot: snapshot)
        }
        // The app pushes reloads whenever state changes; the refresh policy is
        // a safety net only.
        let refresh = Calendar.current.date(byAdding: .hour, value: 2, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}
