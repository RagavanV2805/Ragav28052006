import SwiftUI

/// Compact card for a skill, used in roadmap sections, search results and
/// recommendation lists. Navigation is the caller's job (wrap in a
/// NavigationLink or onTapGesture).
struct SkillCard: View {
    let name: String
    let category: SkillCategory
    let level: Int
    let targetLevel: Int
    let state: RoadmapService.NodeState
    var importance: Int? = nil

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            statusIcon
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(category.displayName)
                        .font(.caption2)
                        .foregroundStyle(Color.csSecondaryText)
                    if let importance {
                        ImportanceBadge(importance: importance)
                    }
                }
            }

            Spacer(minLength: DesignSystem.Spacing.xs)

            VStack(alignment: .trailing, spacing: 3) {
                Text("Lv \(level)/\(targetLevel)")
                    .font(.caption.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(level >= targetLevel ? Color.csSuccess : Color.csSecondaryText)
                ProgressBar(
                    fraction: targetLevel > 0 ? Double(level) / Double(targetLevel) : 0,
                    tint: level >= targetLevel ? .csSuccess : .accentColor,
                    height: 4
                )
                .frame(width: 56)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.control, style: .continuous)
                .fill(Color.csBackground.opacity(0.5))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = ["\(name), \(category.displayName), level \(level) of \(targetLevel)"]
        parts.append("Status: \(statusDescription)")
        return parts.joined(separator: ", ")
    }

    private var statusDescription: String {
        switch state {
        case .locked: return "locked"
        case .available: return "available to start"
        case .inProgress: return "in progress"
        case .completed: return "completed"
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .locked:
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Color.csLocked)
                .accessibilityHidden(true)
        case .available:
            Image(systemName: "circle.dashed")
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
        case .inProgress:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.footnote)
                .foregroundStyle(Color.csWarning)
                .accessibilityHidden(true)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.csSuccess)
                .accessibilityHidden(true)
        }
    }
}

/// Small 1-5 importance indicator.
struct ImportanceBadge: View {
    let importance: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < filledDots ? Color.accentColor : Color.csLocked)
                    .frame(width: 4, height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Importance \(importance) of 5")
    }

    private var filledDots: Int {
        switch importance {
        case 0...2: return 1
        case 3: return 2
        default: return 3
        }
    }
}
