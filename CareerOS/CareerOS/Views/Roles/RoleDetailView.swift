import SwiftUI
import SwiftData

/// Overview of a career role: summary, stage progress, top gaps and the
/// projects attached to it.
struct RoleDetailView: View {
    @Environment(\.modelContext) private var context
    let role: CareerRole

    private var isTarget: Bool {
        PersistenceService.profile(in: context).targetRoleSlug == role.slug
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                header

                if !isTarget {
                    Button {
                        ProfileViewModel().setTargetRole(slug: role.slug, context: context)
                    } label: {
                        Label("Set as Target Role", systemImage: "target")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .accessibilityIdentifier("role.setTarget")
                }

                stageProgressSection
                gapsSection
                projectsSection
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle(role.name)
        .background(Color.csBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: role.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.name)
                        .font(.title2.weight(.bold))
                    Text(role.tagline)
                        .font(.subheadline)
                        .foregroundStyle(Color.csSecondaryText)
                }
            }
            Text(role.summary)
                .font(.callout)
            if isTarget {
                ChipView(text: "Your current target", systemImage: "target", tint: .accentColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .csCard()
    }

    private var stageProgressSection: some View {
        let summary = RoadmapService(context: context).progressSummary(for: role)
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Roadmap by Stage", subtitle: "\(summary.overallPercent)% overall")
            ForEach(summary.byStage) { stageProgress in
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack {
                        Text(stageProgress.stage.displayName)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(stageProgress.completedCount)/\(stageProgress.totalCount)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(Color.csSecondaryText)
                    }
                    ProgressBar(fraction: stageProgress.fraction, height: 6)
                }
            }
        }
        .csCard()
    }

    private var gapsSection: some View {
        let matches = RoleMatchCalculator().match(
            for: RoadmapService(context: context).requirementSnapshots().first { $0.roleSlug == role.slug }
                ?? RoleRequirementSnapshot(roleSlug: role.slug, roleName: role.name, iconName: role.iconName, nodes: []),
            levels: RoadmapService(context: context).userLevels(),
            completedIDs: RoadmapService(context: context).completedSkillSlugs(),
            inProgressIDs: RoadmapService(context: context).inProgressSkillSlugs()
        )

        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Your Biggest Gaps", subtitle: "Highest-impact missing skills first")
            if matches.missingSkillNames.isEmpty && matches.inProgressSkillNames.isEmpty {
                Text("You cover everything this role requires. Keep building projects!")
                    .font(.caption)
                    .foregroundStyle(Color.csSecondaryText)
            } else {
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(matches.missingSkillNames.prefix(8), id: \.self) { name in
                        ChipView(text: name, systemImage: "exclamationmark.circle", tint: .red)
                    }
                    ForEach(matches.inProgressSkillNames.prefix(4), id: \.self) { name in
                        ChipView(text: name, systemImage: "arrow.triangle.2.circlepath", tint: .csWarning)
                    }
                }
            }
        }
        .csCard()
    }

    private var projectsSection: some View {
        let projects = role.projects.sorted { $0.difficulty.sortOrder < $1.difficulty.sortOrder }
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Role Projects", subtitle: "\(projects.count) projects for your portfolio")
            if projects.isEmpty {
                EmptyStateView(systemImage: "hammer", title: "No projects yet", message: "Projects for this role are coming.")
            } else {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        ProjectCard(
                            project: project,
                            status: project.progress?.status ?? .notStarted,
                            fraction: project.milestoneFraction
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
