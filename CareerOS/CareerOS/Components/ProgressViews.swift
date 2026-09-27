import SwiftUI

/// Circular progress indicator used on the dashboard and role cards.
struct ProgressRing: View {
    let fraction: Double
    var size: CGFloat = 64
    var lineWidth: CGFloat = 7
    var tint: Color = .accentColor

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: clamped)
            Text("\(Int((clamped * 100).rounded()))%")
                .font(.system(size: size * 0.24, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

/// Thin linear progress bar.
struct ProgressBar: View {
    let fraction: Double
    var tint: Color = .accentColor
    var height: CGFloat = 8

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.15))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * clamped)
                    .animation(.easeOut(duration: 0.35), value: clamped)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}

/// Small stat block for dashboard/analytics grids.
struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.csSecondaryText)
                    .lineLimit(1)
            }
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .csCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
