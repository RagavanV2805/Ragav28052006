import SwiftUI
import SwiftData

/// The standalone onboarding journey. Deliberately separate from the main
/// TabView: nothing here depends on tab navigation.
struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.step != .welcome {
                    ProgressView(value: viewModel.progressFraction)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.sm)
                        .accessibilityLabel("Onboarding progress")
                        .accessibilityValue("\(Int(viewModel.progressFraction * 100)) percent")
                }

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.csBackground)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                if viewModel.step != .welcome {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { viewModel.goBack() }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .accessibilityIdentifier("onboarding.back")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .welcome:
            OnboardingWelcomeView {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.advance() }
            }
        case .experience:
            OnboardingExperienceView(viewModel: viewModel)
        case .knownSkills:
            OnboardingSkillsView(viewModel: viewModel)
        case .dsaAndFundamentals:
            OnboardingFundamentalsView(viewModel: viewModel)
        case .timeAndTimeline:
            OnboardingTimeView(viewModel: viewModel)
        case .roleSelection:
            OnboardingRoleView(viewModel: viewModel)
        case .review:
            OnboardingReviewView(viewModel: viewModel)
        }
    }
}

// MARK: - Shared step chrome

struct OnboardingStepContainer<Content: View>: View {
    let title: String
    let subtitle: String
    var validationMessage: String? = nil
    var onNext: (() -> Void)? = nil
    var nextTitle: String = "Continue"
    var nextEnabled: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(title)
                            .font(.title.weight(.bold))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.csSecondaryText)
                    }
                    .padding(.top, DesignSystem.Spacing.lg)
                    .accessibilityAddTraits(.isHeader)

                    content()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
            }

            if let onNext {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button(nextTitle) { onNext() }
                        .buttonStyle(.primary)
                        .disabled(!nextEnabled)
                        .accessibilityIdentifier("onboarding.continue")
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.md)
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Welcome

struct OnboardingWelcomeView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            Image(systemName: "map.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("CareerOS")
                    .font(.largeTitle.weight(.bold))
                Text("Your personalised roadmap from learning to your first — or next — engineering role.")
                    .font(.body)
                    .foregroundStyle(Color.csSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                welcomeRow(icon: "target", text: "Pick a target role")
                welcomeRow(icon: "gauge.with.dots.needle.33percent", text: "Tell us what you know")
                welcomeRow(icon: "point.topleft.down.curvedto.point.bottomright.up", text: "Get a personalised path")
                welcomeRow(icon: "chart.line.uptrend.xyaxis", text: "Track progress to the offer")
            }
            .csCard()
            .padding(.horizontal, DesignSystem.Spacing.lg)

            Spacer()

            Button("Get Started") { onStart() }
                .buttonStyle(.primary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
                .accessibilityIdentifier("onboarding.start")
        }
    }

    private func welcomeRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
