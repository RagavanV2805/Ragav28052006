import SwiftUI

/// Card summarising a project with status, difficulty and completion.
struct ProjectCard: View {
    let project: Project
    var status: ProjectStatus? = nil
    var fraction: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(project.summary)
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)
                        .lineLimit(2)
                }
                Spacer(minLength: DesignSystem.Spacing.xs)
                statusBadge
            }

            HStack(spacing: 6) {
                ChipView(
                    text: project.difficulty.displayName,
                    systemImage: difficultyIcon,
                    tint: difficultyTint
                )
                ChipView(text: "~\(project.estimatedWeeks)w", systemImage: "clock")
                if !project.technologyStack.isEmpty {
                    ChipView(text: project.technologyStack.first ?? "", systemImage: "wrench")
                }
            }

            if let fraction, let status, status != .notStarted {
                ProgressBar(fraction: fraction, tint: status == .completed ? .csSuccess : .accentColor, height: 6)
            }
        }
        .csCard()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let status, status != .notStarted {
            ChipView(
                text: status.displayName,
                systemImage: statusIcon(status),
                tint: statusTint(status)
            )
        }
    }

    private func statusIcon(_ status: ProjectStatus) -> String {
        switch status {
        case .notStarted: return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        }
    }

    private func statusTint(_ status: ProjectStatus) -> Color {
        switch status {
        case .notStarted: return Color.csSecondaryText
        case .inProgress: return .accentColor
        case .paused: return .csWarning
        case .completed: return .csSuccess
        }
    }

    private var difficultyIcon: String {
        switch project.difficulty {
        case .beginner: return "leaf"
        case .intermediate: return "flame"
        case .advanced: return "bolt"
        }
    }

    private var difficultyTint: Color {
        switch project.difficulty {
        case .beginner: return .csSuccess
        case .intermediate: return .csWarning
        case .advanced: return .red
        }
    }
}
