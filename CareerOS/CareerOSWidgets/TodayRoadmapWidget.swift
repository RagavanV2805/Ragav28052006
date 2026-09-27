import WidgetKit
import SwiftUI

/// Widget 2 — "Today's roadmap": last done item, the current focus and what's
/// coming next, mirroring the in-app roadmap order.
struct TodayRoadmapWidget: Widget {
    let kind = "TodayRoadmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SharedSnapshotProvider()) { entry in
            TodayRoadmapWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Roadmap")
        .description("Where you are on your roadmap right now.")
        .supportedFamilies([.systemMedium])
    }
}

struct TodayRoadmapWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        let snapshot = entry.snapshot
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Today's Roadmap", systemImage: "map.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.targetRoleName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if snapshot.todayItems.isEmpty {
                VStack(spacing: 4) {
                    Text("No roadmap yet")
                        .font(.subheadline.weight(.semibold))
                    Text("Complete onboarding in CareerOS to see today's focus.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(snapshot.todayItems.indices, id: \.self) { index in
                    row(for: snapshot.todayItems[index])
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func row(for item: WidgetSnapshot.TodayItem) -> some View {
        HStack(spacing: 8) {
            icon(for: item.state)
            Text(item.title)
                .font(item.state == .current ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(item.state == .done ? .secondary : .primary)
                .strikethrough(item.state == .done)
                .lineLimit(1)
            Spacer()
            Text(label(for: item.state))
                .font(.caption2.weight(.medium))
                .foregroundStyle(color(for: item.state))
        }
    }

    @ViewBuilder
    private func icon(for state: WidgetSnapshot.TodayItem.State) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .current:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color.accentColor)
        case .upcoming:
            Image(systemName: "circle.dashed")
                .foregroundStyle(.secondary)
        }
    }

    private func label(for state: WidgetSnapshot.TodayItem.State) -> String {
        switch state {
        case .done: return "Done"
        case .current: return "Today"
        case .upcoming: return "Upcoming"
        }
    }

    private func color(for state: WidgetSnapshot.TodayItem.State) -> Color {
        switch state {
        case .done: return .green
        case .current: return .accentColor
        case .upcoming: return .secondary
        }
    }
}
