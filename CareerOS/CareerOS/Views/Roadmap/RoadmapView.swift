import SwiftUI
import SwiftData

/// Interactive roadmap: stage-grouped skill cards with prerequisite-aware
/// states, search and filters. Stages expand/collapse so the screen stays
/// readable on every device size.
struct RoadmapView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CareerRole.sortOrder) private var roles: [CareerRole]
    @State private var viewModel = RoadmapViewModel()
    @State private var selectedRoleSlug: String?
    /// Bumped whenever the screen becomes visible again so node states pick up
    /// changes made on pushed detail screens.
    @State private var refreshID = 0

    private var selectedRole: CareerRole? {
        roles.first { $0.slug == selectedRoleSlug }
            ?? roles.first { $0.slug == PersistenceService.profile(in: context).targetRoleSlug }
            ?? roles.first
    }

    var body: some View {
        Group {
            if let role = selectedRole {
                roadmapContent(role)
            } else {
                EmptyStateView(
                    systemImage: "map",
                    title: "No roadmaps yet",
                    message: "Roadmaps load automatically on first launch. If this persists, reset data in Profile."
                )
            }
        }
        .navigationTitle("Roadmap")
        .background(Color.csBackground)
        .onAppear { refreshID += 1 }
        .searchable(text: $viewModel.searchText, prompt: "Search skills")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RoleMatchView()
                } label: {
                    Label("Role Match", systemImage: "target")
                }
                .accessibilityIdentifier("roadmap.roleMatch")
            }
        }
    }

    @ViewBuilder
    private func roadmapContent(_ role: CareerRole) -> some View {
        // `refreshID` is read so navigation back into this screen re-evaluates
        // node states and progress.
        let _ = refreshID
        let sections = viewModel.sections(for: role, context: context)
        let summary = RoadmapService(context: context).progressSummary(for: role)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md, pinnedViews: []) {
                header(role: role, summary: summary)

                Picker("Filter", selection: $viewModel.filter) {
                    ForEach(RoadmapViewModel.NodeFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("roadmap.filter")

                if sections.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: viewModel.searchText.isEmpty ? "Nothing here" : "No matches",
                        message: viewModel.searchText.isEmpty
                            ? "This roadmap has no skills matching the current filter."
                            : "No skills match “\(viewModel.searchText)”. Try a different search."
                    )
                } else {
                    ForEach(sections) { section in
                        stageSection(section, role: role)
                    }
                }

                if let optionalNote = optionalSummary(role: role, summary: summary) {
                    Text(optionalNote)
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    private func header(role: CareerRole, summary: RoadmapProgressSummary) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: role.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.name)
                        .font(.headline)
                    Text(viewModel.headline(for: role, context: context))
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)
                }
                Spacer()
                ProgressRing(fraction: summary.overallFraction, size: 52, lineWidth: 5)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(roles) { candidate in
                        Button {
                            selectedRoleSlug = candidate.slug
                        } label: {
                            Text(candidate.name)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 6)
                                .background(
                                    candidate.slug == role.slug ? Color.accentColor : Color.csCard,
                                    in: Capsule()
                                )
                                .foregroundStyle(candidate.slug == role.slug ? .white : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .accessibilityLabel("Choose role to preview")

            legend
        }
        .csCard()
    }

    private var legend: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            legendItem("lock.fill", "Locked", Color.csLocked)
            legendItem("circle.dashed", "Ready", Color.accentColor)
            legendItem("arrow.triangle.2.circlepath", "In Progress", Color.csWarning)
            legendItem("checkmark.circle.fill", "Done", Color.csSuccess)
        }
        .font(.caption2)
        .foregroundStyle(Color.csSecondaryText)
    }

    private func legendItem(_ icon: String, _ label: String, _ tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(label)
        }
    }

    @ViewBuilder
    private func stageSection(_ section: RoadmapViewModel.Section, role: CareerRole) -> some View {
        let expanded = viewModel.isExpanded(section.stage)
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggleStage(section.stage) }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: section.stage.symbolName)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 22)
                    Text(section.stage.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Text("\(section.completedCount)/\(section.items.count)")
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.csSecondaryText)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.csSecondaryText)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(Color.csCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(section.stage.displayName), \(section.completedCount) of \(section.items.count) complete")
            .accessibilityHint(expanded ? "Collapses this stage" : "Expands this stage")

            if expanded {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(section.items) { item in
                        nodeRow(
                            item: item,
                            isLast: item.id == section.items.last?.id,
                            role: role
                        )
                    }
                }
                .padding(.leading, DesignSystem.Spacing.md)
            }
        }
    }

    /// A roadmap node with a vertical connector hinting at learning order.
    private func nodeRow(
        item: RoadmapViewModel.Item,
        isLast: Bool,
        role: CareerRole
    ) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
            VStack(spacing: 0) {
                Circle()
                    .fill(dotColor(for: item.state))
                    .frame(width: 8, height: 8)
                    .padding(.top, 20)
                if !isLast {
                    Rectangle()
                        .fill(Color.csLocked.opacity(0.5))
                        .frame(width: 2)
                }
            }
            .frame(width: 12)

            NavigationLink(value: item.skill) {
                SkillCard(
                    name: item.skill.name,
                    category: item.skill.category,
                    level: viewModel.levelForSkill(item.skill, context: context),
                    targetLevel: item.node.targetLevel,
                    state: item.state,
                    importance: item.node.isOptional ? nil : item.node.importance
                )
                .overlay(alignment: .topTrailing) {
                    if item.node.isOptional {
                        ChipView(text: "Optional", tint: Color.csSecondaryText)
                            .padding(6)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(item.state == .locked)
            .opacity(item.state == .locked ? 0.6 : 1)
            .accessibilityHint(item.state == .locked ? "Locked until prerequisites are complete" : "Opens skill details")
        }
    }

    private func dotColor(for state: RoadmapService.NodeState) -> Color {
        switch state {
        case .locked: return Color.csLocked
        case .available: return Color.accentColor
        case .inProgress: return Color.csWarning
        case .completed: return Color.csSuccess
        }
    }

    private func optionalSummary(role: CareerRole, summary: RoadmapProgressSummary) -> String? {
        guard summary.optionalTotal > 0 else { return nil }
        return "\(summary.optionalCompleted)/\(summary.optionalTotal) optional skills completed — optional skills never block your roadmap."
    }
}
