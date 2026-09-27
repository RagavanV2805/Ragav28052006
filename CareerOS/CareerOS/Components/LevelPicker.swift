import SwiftUI

/// 0...5 self-rating control used during assessment and on skill details.
struct LevelPicker: View {
    @Binding var level: Int
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: compact ? 6 : 8) {
                ForEach(0...5, id: \.self) { value in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            level = value
                        }
                    } label: {
                        Text("\(value)")
                            .font(compact ? .caption.weight(.semibold) : .body.weight(.semibold))
                            .frame(
                                width: compact ? 30 : 40,
                                height: compact ? 30 : 40
                            )
                            .background(
                                Circle().fill(level == value ? Color.accentColor : Color.csBackground)
                            )
                            .foregroundStyle(level == value ? .white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Level \(value)")
                    .accessibilityAddTraits(level == value ? .isSelected : [])
                }
            }
            Text(SkillLevel(clamping: level).displayName)
                .font(.caption)
                .foregroundStyle(Color.csSecondaryText)
                .contentTransition(.opacity)
        }
    }
}
