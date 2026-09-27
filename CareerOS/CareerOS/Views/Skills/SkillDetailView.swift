import SwiftUI
import SwiftData

/// Full detail for one skill: level control, prerequisite graph, unlocks,
/// resources, suggested projects, notes and completion actions.
struct SkillDetailView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: SkillDetailViewModel
    @State private var notes: String = ""
    @State private var showLogSession = false
    @State private var sessionMinutes = 30

    init(skill: Skill) {
        _viewModel = State(initialValue: SkillDetailViewModel(skill: skill))
    }

    private var skill: Skill { viewModel.skill }
    private var progress: SkillProgress? { viewModel.progress }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                headerCard
                levelCard
                if viewModel.state == .locked {
                    lockedBanner
                }
                prerequisitesCard
                unlocksCard
                resourcesCard
                projectsCard
                notesCard
                completionActions
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle(skill.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.csBackground)
        .onAppear {
            viewModel.load(context: context)
            notes = progress?.personalNotes ?? ""
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLogSession = true
                } label: {
                    Label("Log Time", systemImage: "clock.badge.plus")
                }
            }
        }
        .alert("Log Learning Time", isPresented: $showLogSession) {
            TextField("Minutes", value: $sessionMinutes, format: .number)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Log") {
                viewModel.logSession(minutes: sessionMinutes, context: context)
            }
        } message: {
            Text("How many minutes did you spend on \(skill.name)?")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ChipView(text: skill.category.displayName, systemImage: skill.category.symbolName)
                if let importance = viewModel.importance {
                    ChipView(text: "Importance \(importance)/5", systemImage: "star.fill", tint: .orange)
                }
                if let target = viewModel.targetLevel {
                    ChipView(text: "Target Lv \(target)", systemImage: "target")
                }
            }
            Text(skill.summary)
                .font(.callout)
            HStack(spacing: DesignSystem.Spacing.md) {
                Label("\(Int(skill.estimatedHours))h estimated effort", systemImage: "clock")
                Label(statusLabel, systemImage: statusIcon)
            }
            .font(.caption)
            .foregroundStyle(Color.csSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .csCard()
    }

    private var statusLabel: String {
        progress?.status.displayName ?? SkillStatus.notStarted.displayName
    }

    private var statusIcon: String {
        switch progress?.status ?? .notStarted {
        case .notStarted: return "circle.dashed"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        }
    }

    // MARK: - Level

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Your Level")
            LevelPicker(
                level: Binding(
                    get: { progress?.level ?? 0 },
                    set: { viewModel.updateLevel($0, context: context) }
                )
            )
            if let target = viewModel.targetLevel, let level = progress?.level {
                ProgressBar(
                    fraction: target > 0 ? Double(min(level, target)) / Double(target) : 0,
                    tint: level >= target ? .csSuccess : .accentColor
                )
                Text(level >= target
                     ? "You've reached the target level for your role."
                     : "Target level for your role: \(target)")
                    .font(.caption)
                    .foregroundStyle(Color.csSecondaryText)
            }
        }
        .csCard()
    }

    private var lockedBanner: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Color.csWarning)
            Text("This skill has unmet prerequisites. Finish them first so this knowledge sticks.")
                .font(.caption)
                .foregroundStyle(Color.csSecondaryText)
        }
        .padding(DesignSystem.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.csWarning.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
    }

    // MARK: - Prerequisites & unlocks

    @ViewBuilder
    private var prerequisitesCard: some View {
        if !skill.prerequisiteEdges.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SectionHeader(title: "Prerequisites")
                ForEach(skill.prerequisiteEdges, id: \.persistentModelID) { edge in
                    if let prereq = edge.prerequisite {
                        NavigationLink(value: prereq) {
                            prerequisiteRow(skill: prereq, required: edge.isRequired)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .csCard()
        }
    }

    private func prerequisiteRow(skill prereq: Skill, required: Bool) -> some View {
        let satisfied = RoadmapService(context: context).satisfiedSkillSlugs().contains(prereq.slug)
        return HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: satisfied ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(satisfied ? Color.csSuccess : Color.csLocked)
            VStack(alignment: .leading, spacing: 1) {
                Text(prereq.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                Text(required ? "Required" : "Recommended")
                    .font(.caption2)
                    .foregroundStyle(Color.csSecondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.csSecondaryText)
        }
        .padding(DesignSystem.Spacing.xs)
        .background(Color.csBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var unlocksCard: some View {
        let unlocks = skill.unlocks
        if !unlocks.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SectionHeader(title: "What This Unlocks")
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(unlocks) { unlocked in
                        NavigationLink(value: unlocked) {
                            ChipView(text: unlocked.name, systemImage: "lock.open")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .csCard()
        }
    }

    // MARK: - Resources

    @ViewBuilder
    private var resourcesCard: some View {
        let resources = skill.resources.sorted { ($0.kind.rawValue) < ($1.kind.rawValue) }
        if !resources.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SectionHeader(title: "Learning Resources")
                ForEach(resources) { resource in
                    ResourceRow(resource: resource)
                    Divider().opacity(resource.id == resources.last?.id ? 0 : 0.5)
                }
            }
            .csCard()
        }
    }

    // MARK: - Projects

    @ViewBuilder
    private var projectsCard: some View {
        if !viewModel.suggestedProjects.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SectionHeader(title: "Suggested Projects")
                ForEach(viewModel.suggestedProjects.prefix(3)) { project in
                    NavigationLink(value: project) {
                        ProjectCard(project: project, status: project.progress?.status ?? .notStarted, fraction: project.milestoneFraction)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Personal Notes")
            TextEditor(text: $notes)
                .frame(minHeight: 90)
                .scrollContentBackground(.hidden)
                .padding(DesignSystem.Spacing.xs)
                .background(Color.csBackground, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                .onChange(of: notes) { _, newValue in
                    viewModel.saveNotes(newValue, context: context)
                }
                .accessibilityLabel("Personal notes for \(skill.name)")
        }
        .csCard()
    }

    // MARK: - Actions

    @ViewBuilder
    private var completionActions: some View {
        switch progress?.status ?? .notStarted {
        case .notStarted:
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    viewModel.start(context: context)
                } label: {
                    Label("Start Learning", systemImage: "play.fill")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("skill.start")

                Button("Mark Complete") {
                    viewModel.markComplete(context: context)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("skill.complete")
            }
        case .inProgress:
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    viewModel.markComplete(context: context)
                } label: {
                    Label("Mark Complete", systemImage: "checkmark")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("skill.complete")
            }
        case .completed:
            VStack(spacing: DesignSystem.Spacing.xs) {
                Label("Completed \(progress?.completedAt.map { formatted($0) } ?? "")", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.csSuccess)
                    .accessibilityIdentifier("skill.completedLabel")
                Button("Reopen") {
                    viewModel.reopen(context: context)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
