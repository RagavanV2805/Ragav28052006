import WidgetKit
import SwiftUI

/// Widget 1 — "What's next": the current learning goal and overall progress.
/// Small shows the essential glance; medium adds the reason line.
struct NextSkillWidget: Widget {
    let kind = "NextSkillWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SharedSnapshotProvider()) { entry in
            NextSkillWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Skill")
        .description("Your current learning goal and what to learn next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextSkillWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        let snapshot = entry.snapshot
        Group {
            if family == .systemSmall {
                smallBody(snapshot)
            } else {
                mediumBody(snapshot)
            }
        }
    }

    private func smallBody(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(snapshot.targetRoleName, systemImage: "target")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(snapshot.nextSkillName.map { "Learn \($0)" } ?? "Set a goal")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                ProgressView(value: Double(snapshot.overallPercent) / 100)
                    .tint(.accentColor)
                Text("\(snapshot.overallPercent)%")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
            }
        }
    }

    private func mediumBody(_ snapshot: WidgetSnapshot) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(snapshot.targetRoleName, systemImage: "target")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(snapshot.nextSkillName.map { "Learn \($0) next" } ?? "Choose a target role")
                    .font(.title3.weight(.bold))
                    .lineLimit(2)

                if let reason = snapshot.nextSkillReason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: Double(snapshot.overallPercent) / 100)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(snapshot.overallPercent)%")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                }
                .frame(width: 56, height: 56)

                if snapshot.streakDays > 0 {
                    Label("\(snapshot.streakDays)d", systemImage: "flame.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
