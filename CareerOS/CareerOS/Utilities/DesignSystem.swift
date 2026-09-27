import SwiftUI

/// Central design tokens. Every view pulls spacing, radii and colors from
/// here so the app stays visually consistent and dark-mode safe.
enum DesignSystem {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let control: CGFloat = 10
        static let card: CGFloat = 16
        static let sheet: CGFloat = 24
    }

    enum Shadow {
        static let cardRadius: CGFloat = 8
        static let cardY: CGFloat = 2
        static let cardOpacity: Double = 0.06
    }
}

// MARK: - Semantic colors

extension Color {
    /// Card surface that adapts to light/dark automatically.
    static var csCard: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.secondarySystemGroupedBackground
                : UIColor.systemBackground
        })
    }

    static var csBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    static var csSecondaryText: Color {
        Color(uiColor: .secondaryLabel)
    }

    static var csSuccess: Color { .green }
    static var csWarning: Color { .orange }
    static var csLocked: Color { Color(uiColor: .tertiaryLabel) }
}

// MARK: - Card container

struct CSCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card, style: .continuous)
                    .fill(Color.csCard)
                    .shadow(
                        color: .black.opacity(DesignSystem.Shadow.cardOpacity),
                        radius: DesignSystem.Shadow.cardRadius,
                        y: DesignSystem.Shadow.cardY
                    )
            )
    }
}

extension View {
    /// Standard rounded card treatment.
    func csCard(padding: CGFloat = DesignSystem.Spacing.md) -> some View {
        modifier(CSCardModifier(padding: padding))
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control, style: .continuous))
            .foregroundStyle(.white)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.csSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Chip

struct ChipView: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(tint.opacity(0.12), in: Capsule())
        .foregroundStyle(tint)
    }
}
