import SwiftUI

/// A single learning resource row. URLs live in the model — never in views.
struct ResourceRow: View {
    let resource: Resource
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = resource.url {
                openURL(url)
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: resource.kind.symbolName)
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(resource.title)
                        .font(.subheadline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 4) {
                        Text(resource.kind.displayName)
                        if !resource.author.isEmpty {
                            Text("•")
                            Text(resource.author)
                        }
                        Text("•")
                        Text(resource.displayHost)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.csSecondaryText)
                    .lineLimit(1)
                }

                Spacer(minLength: DesignSystem.Spacing.xs)

                if !resource.isFree {
                    ChipView(text: "Paid", tint: .csWarning)
                }
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Color.csSecondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(resource.kind.displayName): \(resource.title)\(resource.author.isEmpty ? "" : " by \(resource.author)")")
        .accessibilityHint("Opens in your browser")
    }
}
