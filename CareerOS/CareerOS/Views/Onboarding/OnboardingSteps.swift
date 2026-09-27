import SwiftUI
import SwiftData

// MARK: - Experience

struct OnboardingExperienceView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            title: "About you",
            subtitle: "This helps calibrate where your roadmap starts.",
            onNext: { withAnimation { viewModel.advance() } }
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Your name (optional)")
                        .font(.subheadline.weight(.medium))
                    TextField("What should we call you?", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("onboarding.name")
                }

                Text("Where are you today?")
                    .font(.subheadline.weight(.medium))
                    .padding(.top, DesignSystem.Spacing.xs)

                ForEach(ExperienceLevel.allCases) { level in
                    Button {
                        viewModel.experienceLevel = level
                    } label: {
                        HStack {
                            Image(systemName: viewModel.experienceLevel == level ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.experienceLevel == level ? Color.accentColor : Color.csLocked)
                            Text(level.displayName)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.control)
                                .fill(viewModel.experienceLevel == level ? Color.accentColor.opacity(0.08) : Color.csCard)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(viewModel.experienceLevel == level ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - Known skills & languages

struct OnboardingSkillsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Query(sort: \Skill.name) private var allSkills: [Skill]

    var body: some View {
        OnboardingStepContainer(
            title: "What do you know?",
            subtitle: "Tap what you've used, then rate how comfortable you are. Be honest — this sets your starting point.",
            onNext: { withAnimation { viewModel.advance() } }
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Programming languages you've used")
                    .font(.subheadline.weight(.medium))

                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(viewModel.languageChoices(from: allSkills)) { skill in
                        let isOn = viewModel.knownSkillSlugs.contains(skill.slug)
                        Button {
                            if isOn {
                                viewModel.knownSkillSlugs.remove(skill.slug)
                                viewModel.skillRatings.removeValue(forKey: skill.slug)
                            } else {
                                viewModel.knownSkillSlugs.insert(skill.slug)
                                viewModel.skillRatings[skill.slug, default: SkillLevel.basic.rawValue] = viewModel.skillRatings[skill.slug] ?? SkillLevel.basic.rawValue
                            }
                        } label: {
                            Text(skill.name)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(isOn ? Color.accentColor : Color.csCard, in: Capsule())
                                .foregroundStyle(isOn ? .white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isOn ? [.isSelected] : [])
                    }
                }

                Divider().padding(.vertical, DesignSystem.Spacing.xs)

                Text("Rate your current skills")
                    .font(.subheadline.weight(.medium))

                ForEach(viewModel.assessmentSkillChoices(from: allSkills)) { skill in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(skill.name)
                            .font(.subheadline.weight(.medium))
                        LevelPicker(
                            level: Binding(
                                get: { viewModel.skillRatings[skill.slug] ?? 0 },
                                set: { viewModel.skillRatings[skill.slug] = $0 }
                            ),
                            compact: true
                        )
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.csCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                }
            }
        }
    }
}

// MARK: - DSA & CS fundamentals

struct OnboardingFundamentalsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            title: "Core foundations",
            subtitle: "Rough level is fine — you can refine any of this later.",
            onNext: { withAnimation { viewModel.advance() } }
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Data structures & algorithms")
                        .font(.subheadline.weight(.medium))
                    LevelPicker(level: $viewModel.dsaLevel)
                }
                .csCard()

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("CS fundamentals (OS, networks, databases)")
                        .font(.subheadline.weight(.medium))
                    LevelPicker(level: $viewModel.csFundamentalsLevel)
                }
                .csCard()

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Projects you've completed")
                        .font(.subheadline.weight(.medium))
                    Stepper(value: $viewModel.completedProjectsCount, in: 0...50) {
                        Text("\(viewModel.completedProjectsCount) project\(viewModel.completedProjectsCount == 1 ? "" : "s")")
                            .font(.body)
                    }
                }
                .csCard()
            }
        }
    }
}

// MARK: - Time & timeline

struct OnboardingTimeView: View {
    @Bindable var viewModel: OnboardingViewModel

    private let timeOptions = [30, 60, 90, 120, 180, 240]
    private let timelineOptions = [3, 6, 9, 12, 18, 24]

    var body: some View {
        OnboardingStepContainer(
            title: "Time you can invest",
            subtitle: "Recommendations and effort estimates adapt to this.",
            onNext: { withAnimation { viewModel.advance() } }
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Learning time per day")
                        .font(.subheadline.weight(.medium))
                    FlowLayout(spacing: DesignSystem.Spacing.xs) {
                        ForEach(timeOptions, id: \.self) { minutes in
                            choiceChip(
                                title: minutes >= 60 ? "\(minutes / 60)h\(minutes % 60 > 0 ? " \(minutes % 60)m" : "")" : "\(minutes)m",
                                isSelected: viewModel.dailyMinutes == minutes
                            ) {
                                viewModel.dailyMinutes = minutes
                            }
                        }
                    }
                }
                .csCard()

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Target timeline")
                        .font(.subheadline.weight(.medium))
                    FlowLayout(spacing: DesignSystem.Spacing.xs) {
                        ForEach(timelineOptions, id: \.self) { months in
                            choiceChip(title: "\(months) months", isSelected: viewModel.targetMonths == months) {
                                viewModel.targetMonths = months
                            }
                        }
                    }
                }
                .csCard()

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("How confident do you feel about your direction?")
                        .font(.subheadline.weight(.medium))
                    LevelPicker(level: $viewModel.confidenceLevel)
                }
                .csCard()
            }
        }
    }

    private func choiceChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? Color.accentColor : Color.csBackground, in: Capsule())
                .foregroundStyle(isSelected ? .white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Role selection

struct OnboardingRoleView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Query(sort: \CareerRole.sortOrder) private var roles: [CareerRole]

    var body: some View {
        OnboardingStepContainer(
            title: "Choose your target role",
            subtitle: "You'll get a personalised roadmap for it. You can change this anytime without losing progress.",
            validationMessage: viewModel.validationMessage,
            onNext: { withAnimation { viewModel.advance() } },
            nextEnabled: viewModel.canAdvance()
        ) {
            RoleSelectionGrid(selectedSlug: $viewModel.targetRoleSlug, roles: roles)
        }
    }
}

/// Reusable role grid — also used from Profile to change the target role.
struct RoleSelectionGrid: View {
    @Binding var selectedSlug: String?
    let roles: [CareerRole]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.sm) {
            ForEach(roles) { role in
                let isSelected = selectedSlug == role.slug
                Button {
                    selectedSlug = role.slug
                } label: {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: role.iconName)
                            .font(.title2)
                            .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                        Text(role.name)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                        Text(role.tagline)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.csSecondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.control)
                            .fill(isSelected ? Color.accentColor : Color.csCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.control)
                            .strokeBorder(isSelected ? Color.clear : Color.accentColor.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("role.\(role.slug)")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

// MARK: - Review

struct OnboardingReviewView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var context
    @Query(sort: \CareerRole.sortOrder) private var roles: [CareerRole]
    @State private var isFinishing = false

    var body: some View {
        OnboardingStepContainer(
            title: "You're set",
            subtitle: "We'll build your roadmap from here.",
            onNext: {
                isFinishing = true
                Task { await viewModel.finish(context: context) }
            },
            nextTitle: isFinishing ? "Setting things up…" : "Start Learning",
            nextEnabled: !isFinishing
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                reviewRow("Target role", roles.first { $0.slug == viewModel.targetRoleSlug }?.name ?? "—")
                reviewRow("Experience", viewModel.experienceLevel.displayName)
                reviewRow("Daily learning time", "\(viewModel.dailyMinutes) minutes")
                reviewRow("Timeline", "\(viewModel.targetMonths) months")
                reviewRow("Skills rated", "\(viewModel.skillRatings.count)")
                reviewRow("Projects completed", "\(viewModel.completedProjectsCount)")

                Text("You can adjust any of this later in Profile. Historical progress is always kept when you switch roles.")
                    .font(.footnote)
                    .foregroundStyle(Color.csSecondaryText)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
            .csCard()
        }
    }

    private func reviewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.csSecondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Simple flow layout for chips

/// Minimal wrapping layout for chip groups (avoids external dependencies).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? 0
        let height = rows.reduce(CGFloat(0)) { acc, row in
            acc + row.height + (acc > 0 ? spacing : 0)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var height: CGFloat = 0
        var width: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let projectedWidth = current.width + size.width + (current.indices.isEmpty ? 0 : spacing)
            if projectedWidth > maxWidth && !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.indices.append(index)
            current.width = current.width + size.width + (current.indices.count > 1 ? spacing : 0)
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
