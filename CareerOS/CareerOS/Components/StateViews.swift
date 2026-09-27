import SwiftUI

/// Friendly empty state used anywhere a list may legitimately have nothing.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Color.csSecondaryText)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.csSecondaryText)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .fixedSize()
                    .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Deterministic loading indicator for async work.
struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.csSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Recoverable error display with retry.
struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.csWarning)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.csSecondaryText)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Try Again", action: retry)
                    .buttonStyle(.bordered)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Three-state wrapper: loading / error / content. Keeps screens uniform.
enum ViewState<Value> {
    case loading
    case failed(String)
    case loaded(Value)
}

struct StateView<Value, Content: View>: View {
    let state: ViewState<Value>
    var retry: (() -> Void)? = nil
    @ViewBuilder var content: (Value) -> Content

    var body: some View {
        switch state {
        case .loading:
            LoadingView()
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}
