import SwiftUI
import SwiftData

/// Project workspace: milestones, status, deadline, notes and skill fit.
struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: ProjectDetailViewModel
    @State private var notes: String = ""
    @State private var deadline: Date = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: .now) ?? .now
    @State private var hasDeadline = false

    init(project: Project) {
        _viewModel = State(initialValue: ProjectDetailViewModel(project: project))
    }

    private var project: Project { viewModel.project }

    private var record: ProjectProgress? { project.progress }
    private var status: ProjectStatus { record?.status ?? .notStarted }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                header
                if !viewModel.isEligible(context: context) {
                    eligibilityBanner
                }
                statusControls
                milestonesCard
                detailsCard
                deadlineCard
                notesCard
                outcomesCard
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.csBackground)
        .onAppear {
            notes = record?.notes ?? ""
            if let existing = record?.deadline {
                deadline = existing
                hasDeadline = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(project.summary)
                .font(.callout)
            HStack(spacing: DesignSystem.Spacing.xs) {
                ChipView(text: project.difficulty.displayName, systemImage: "gauge.medium")
                ChipView(text: "~\(project.estimatedWeeks) weeks", systemImage: "clock")
                ChipView(text: "\(Int((viewModel.fraction * 100).rounded()))% done", systemImage: "chart.bar")
            }
            if !project.technologyStack.isEmpty {
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(project.technologyStack, id: \.self) { tech in
                        ChipView(text: tech, tint: Color.csSecondaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .csCard()
    }

    private var eligibilityBanner: some View {
        let satisfied = viewModel.satisfiedRequiredSkills(context: context)
        let missing = project.requiredSkills.filter { !satisfied.contains($0.slug) }
        return HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.csWarning)
            VStack(alignment: .leading, spacing: 4) {
                Text("Missing suggested skills")
                    .font(.caption.weight(.semibold))
                Text("Consider learning first: \(missing.map(\.name).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(Color.csSecondaryText)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.csWarning.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
    }

    // MARK: - Status controls

    @ViewBuilder
    private var statusControls: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            switch status {
            case .notStarted:
                Button {
                    viewModel.start(context: context)
                } label: {
                    Label("Start Project", systemImage: "play.fill")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("project.start")
            case .inProgress:
                Button {
                    viewModel.pause(context: context)
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)
                Button {
                    viewModel.markCompleted(context: context)
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("project.complete")
            case .paused:
                Button {
                    viewModel.resume(context: context)
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.primary)
                Button {
                    viewModel.markCompleted(context: context)
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .buttonStyle(.bordered)
            case .completed:
                Label("Completed \(record?.completedAt.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "")",
                      systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.csSuccess)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("project.completedLabel")
            }
        }
    }

    // MARK: - Milestones

    private var milestonesCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(
                title: "Milestones",
                subtitle: "\(project.orderedMilestones.filter(\.isDone).count) of \(project.orderedMilestones.count) complete"
            )
            ProgressBar(fraction: viewModel.fraction, tint: status == .completed ? .csSuccess : .accentColor, height: 6)

            if project.orderedMilestones.isEmpty {
                Text("No milestones defined for this project.")
                    .font(.caption)
                    .foregroundStyle(Color.csSecondaryText)
            } else {
                ForEach(project.orderedMilestones, id: \.persistentModelID) { milestone in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            viewModel.toggleMilestone(milestone, context: context)
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: milestone.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(milestone.isDone ? Color.csSuccess : Color.csLocked)
                            Text(milestone.title)
                                .font(.subheadline)
                                .strikethrough(milestone.isDone, color: Color.csSecondaryText)
                                .foregroundStyle(milestone.isDone ? Color.csSecondaryText : Color.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Milestone: \(milestone.title)")
                    .accessibilityValue(milestone.isDone ? "Completed" : "Not completed")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .csCard()
    }

    // MARK: - Required skills

    private var detailsCard: some View {
        let satisfied = viewModel.satisfiedRequiredSkills(context: context)
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Skills")
            if !project.requiredSkills.isEmpty {
                Text("Required")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.csSecondaryText)
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(project.requiredSkills) { skill in
                        let met = satisfied.contains(skill.slug)
                        ChipView(
                            text: skill.name,
                            systemImage: met ? "checkmark.circle.fill" : "circle.dashed",
                            tint: met ? .csSuccess : .csWarning
                        )
                    }
                }
            }
            if !project.optionalSkills.isEmpty {
                Text("Nice to have")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.csSecondaryText)
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(project.optionalSkills) { skill in
                        ChipView(text: skill.name, tint: Color.csSecondaryText)
                    }
                }
            }
        }
        .csCard()
    }

    // MARK: - Deadline

    private var deadlineCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Deadline")
            Toggle("Set a deadline", isOn: $hasDeadline)
                .onChange(of: hasDeadline) { _, isOn in
                    viewModel.setDeadline(isOn ? deadline : nil, context: context)
                }
            if hasDeadline {
                DatePicker("Due date", selection: $deadline, in: Date.now..., displayedComponents: .date)
                    .onChange(of: deadline) { _, newValue in
                        viewModel.setDeadline(newValue, context: context)
                    }
                Text("You'll get a reminder the day before.")
                    .font(.caption2)
                    .foregroundStyle(Color.csSecondaryText)
            }
        }
        .csCard()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Notes")
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .padding(DesignSystem.Spacing.xs)
                .background(Color.csBackground, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                .onChange(of: notes) { _, newValue in
                    viewModel.saveNotes(newValue, context: context)
                }
                .accessibilityLabel("Project notes")
        }
        .csCard()
    }

    // MARK: - Outcomes

    @ViewBuilder
    private var outcomesCard: some View {
        if !project.learningOutcomes.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SectionHeader(title: "What You'll Learn")
                ForEach(project.learningOutcomes, id: \.self) { outcome in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 2)
                        Text(outcome)
                            .font(.caption)
                    }
                }
            }
            .csCard()
        }
    }
}
