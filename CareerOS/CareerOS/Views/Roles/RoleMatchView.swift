import SwiftUI
import SwiftData
import Charts

/// Role Match: transparent coverage of every supported role. Explicitly framed
/// as arithmetic, not judgement.
struct RoleMatchView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = RoleMatchViewModel()

    var body: some View {
        StateView(state: viewModel.state, retry: {
            Task { await viewModel.load(context: context) }
        }) { matches in
            matchContent(matches)
        }
        .navigationTitle("Role Match")
        .background(Color.csBackground)
        .task { await viewModel.load(context: context) }
    }

    @ViewBuilder
    private func matchContent(_ matches: [RoleMatch]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("How much of each role's skill set you already cover, weighted by importance. Change your target any time — progress is never lost.")
                    .font(.footnote)
                    .foregroundStyle(Color.csSecondaryText)
                    .csCard(padding: DesignSystem.Spacing.sm)

                matchChart(matches)

                ForEach(matches) { match in
                    NavigationLink {
                        RoleMatchDetailView(match: match)
                    } label: {
                        matchRow(match)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    private func matchChart(_ matches: [RoleMatch]) -> some View {
        Chart(matches.sorted { $0.matchPercent > $1.matchPercent }.prefix(8), id: \.roleSlug) { match in
            BarMark(
                x: .value("Match", match.matchPercent),
                y: .value("Role", match.roleName)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .annotation(position: .trailing) {
                Text("\(match.matchPercent)%")
                    .font(.caption2)
                    .foregroundStyle(Color.csSecondaryText)
            }
        }
        .chartXScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: [0, 25, 50, 75, 100])
        }
        .frame(height: 260)
        .csCard()
        .accessibilityLabel("Bar chart of role match percentages")
    }

    private func matchRow(_ match: RoleMatch) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: match.iconName)
                    .foregroundStyle(Color.accentColor)
                Text(match.roleName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Spacer()
                Text("\(match.matchPercent)%")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Color.primary)
                    .accessibilityIdentifier("rolematch.percent.\(match.roleSlug)")
            }
            ProgressBar(fraction: Double(match.matchPercent) / 100, height: 6)
            HStack(spacing: DesignSystem.Spacing.xs) {
                ChipView(text: "\(match.matchedSkillNames.count) matched", tint: .csSuccess)
                ChipView(text: "\(match.missingSkillNames.count + match.inProgressSkillNames.count) to go", tint: .csWarning)
            }
        }
        .csCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.roleName), \(match.matchPercent) percent match")
        .accessibilityHint("Shows matching and missing skills")
    }
}

/// Per-role transparent breakdown.
struct RoleMatchDetailView: View {
    let match: RoleMatch
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Query(sort: \CareerRole.sortOrder) private var roles: [CareerRole]

    private var isTarget: Bool {
        roles.first { $0.slug == match.roleSlug }?.slug == PersistenceService.profile(in: context).targetRoleSlug
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: match.iconName)
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.roleName)
                            .font(.title3.weight(.semibold))
                        Text("\(match.matchPercent)% of required skills covered")
                            .font(.caption)
                            .foregroundStyle(Color.csSecondaryText)
                    }
                    Spacer()
                }
                .csCard()

                if !isTarget {
                    Button {
                        let vm = RoleMatchViewModel()
                        vm.setTargetRole(slug: match.roleSlug, context: context)
                        router.switchTo(.roadmap)
                    } label: {
                        Label("Set as Target Role", systemImage: "target")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                } else {
                    ChipView(text: "Current target", systemImage: "target", tint: .accentColor)
                }

                breakdownSection(
                    title: "Existing skills",
                    subtitle: "You already cover these at the level this role needs.",
                    names: match.matchedSkillNames,
                    tint: .csSuccess,
                    emptyMessage: "None matched yet — start with the roadmap's fundamentals."
                )
                breakdownSection(
                    title: "In progress",
                    subtitle: "Partially covered right now.",
                    names: match.inProgressSkillNames,
                    tint: .csWarning,
                    emptyMessage: "Nothing marked in progress for this role."
                )
                breakdownSection(
                    title: "Missing skills",
                    subtitle: "Required for this role and not yet covered.",
                    names: match.missingSkillNames,
                    tint: .red,
                    emptyMessage: "Nothing missing — you cover every required skill."
                )
                breakdownSection(
                    title: "Optional skills",
                    subtitle: "Covered optionals — nice bonuses, never required.",
                    names: match.optionalSkillNames,
                    tint: Color.csSecondaryText,
                    emptyMessage: "No optional skills covered yet."
                )

                if let role = roles.first(where: { $0.slug == match.roleSlug }) {
                    NavigationLink(value: role) {
                        Label("View full roadmap", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle(match.roleName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.csBackground)
    }

    @ViewBuilder
    private func breakdownSection(
        title: String,
        subtitle: String,
        names: [String],
        tint: Color,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            SectionHeader(title: title, subtitle: subtitle)
            if names.isEmpty {
                Text(emptyMessage)
                    .font(.caption)
                    .foregroundStyle(Color.csSecondaryText)
                    .padding(DesignSystem.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.csCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
            } else {
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(names, id: \.self) { name in
                        ChipView(text: name, tint: tint)
                    }
                }
            }
        }
    }
}
