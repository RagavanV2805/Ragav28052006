import SwiftUI
import SwiftData
import Charts

/// The home screen: focused, progressive disclosure. The most important
/// signal (what to learn next) sits at the top; detail lives one tap away.
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DashboardViewModel()
    @State private var showLogSession = false

    var body: some View {
        Group {
            StateView(state: viewModel.state, retry: {
                Task { await viewModel.load(context: context) }
            }) { data in
                dashboardContent(data)
            }
            .accessibilityIdentifier("dashboard.content")
        }
        .navigationTitle("CareerOS")
        .background(Color.csBackground)
        .task { await viewModel.load(context: context) }
        .onAppear { viewModel.refresh(context: context) }
        .refreshable { viewModel.refresh(context: context) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLogSession = true
                } label: {
                    Label("Log Learning", systemImage: "plus.circle")
                }
                .accessibilityIdentifier("dashboard.logSession")
            }
        }
        .sheet(isPresented: $showLogSession) {
            LogSessionSheet()
        }
    }

    @ViewBuilder
    private func dashboardContent(_ data: DashboardData) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                if let role = data.targetRole, let summary = data.progressSummary {
                    goalCard(role: role, summary: summary, streakLength: data.streakLength, streakAtRisk: data.streakAtRisk)
                    recommendationCard(data)
                    statsRow(data)
                    projectSection(data)
                    weeklyCard(data)
                    deadlinesSection(data)
                    recentlyCompletedSection(data)
                } else {
                    noGoalCard
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    // MARK: - Goal

    private func goalCard(role: CareerRole, summary: RoadmapProgressSummary, streakLength: Int, streakAtRisk: Bool) -> some View {
        NavigationLink(value: role) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ProgressRing(fraction: summary.overallFraction, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target role")
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)
                    Text(role.name)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text("\(summary.requiredCompleted) of \(summary.requiredTotal) skills complete")
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(streakLength > 0 ? Color.csWarning : Color.csLocked)
                        Text(streakLength > 0
                             ? "\(streakLength)-day streak\(streakAtRisk ? " — learn today to keep it" : "")"
                             : "Start your streak today")
                            .font(.caption)
                            .foregroundStyle(Color.csSecondaryText)
                    }
                    .padding(.top, 2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.csSecondaryText)
            }
            .csCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dashboard.goalCard")
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens your target role details")
    }

    // MARK: - Recommendation

    @ViewBuilder
    private func recommendationCard(_ data: DashboardData) -> some View {
        if let primary = data.plan?.primary {
            RecommendationCard(recommendation: primary, title: "Learn next") {
                viewModel.startRecommended(primary, context: context)
            } openSkill: { skillID in
                if let skill = PersistenceService.skill(slug: skillID, in: context) {
                    router.openSkill(skill)
                }
            }
        } else if let blocker = data.plan?.blockerSuggestions.first {
            RecommendationCard(recommendation: blocker, title: "Unblock your roadmap") {
                viewModel.startRecommended(blocker, context: context)
            } openSkill: { skillID in
                if let skill = PersistenceService.skill(slug: skillID, in: context) {
                    router.openSkill(skill)
                }
            }
        } else if data.plan?.isEmpty == true {
            EmptyStateView(
                systemImage: "checkmark.seal.fill",
                title: "Roadmap complete!",
                message: "You've covered every skill for your target role. Time to build and interview."
            )
            .csCard(padding: DesignSystem.Spacing.xs)
        }
    }

    // MARK: - Stats

    private func statsRow(_ data: DashboardData) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            StatTile(title: "Completed", value: "\(data.skillsCompleted)", systemImage: "checkmark.circle.fill", tint: .csSuccess)
            StatTile(title: "In Progress", value: "\(data.skillsInProgress)", systemImage: "arrow.triangle.2.circlepath", tint: .csWarning)
            StatTile(title: "Streak", value: "\(data.streakLength)d", systemImage: "flame.fill", tint: .orange)
        }
    }

    // MARK: - Current project

    @ViewBuilder
    private func projectSection(_ data: DashboardData) -> some View {
        if let current = data.currentProject {
            SectionHeader(title: "Current Project")
            NavigationLink(value: current.project) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(current.project.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        ChipView(
                            text: current.project.difficulty.displayName,
                            tint: .accentColor
                        )
                    }
                    ProgressBar(fraction: current.fraction, height: 6)
                    Text("\(Int((current.fraction * 100).rounded()))% of milestones done")
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)
                }
                .csCard()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekly chart

    private func weeklyCard(_ data: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "This Week")
            WeeklyActivityChart(days: data.weeklyActivity)
                .frame(height: 96)
        }
        .csCard()
    }

    // MARK: - Deadlines

    @ViewBuilder
    private func deadlinesSection(_ data: DashboardData) -> some View {
        if !data.upcomingDeadlines.isEmpty {
            SectionHeader(title: "Upcoming Deadlines")
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(data.upcomingDeadlines) { entry in
                    NavigationLink(value: entry.project) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(entry.deadline < Date.now.addingTimeInterval(3 * 24 * 3600) ? Color.red : Color.csWarning)
                            Text(entry.project.title)
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Text(entry.deadline, style: .relative)
                                .font(.caption)
                                .foregroundStyle(Color.csSecondaryText)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(Color.csCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.control))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recently completed

    @ViewBuilder
    private func recentlyCompletedSection(_ data: DashboardData) -> some View {
        if !data.recentlyCompleted.isEmpty {
            SectionHeader(title: "Recently Completed")
            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                ForEach(data.recentlyCompleted) { skill in
                    ChipView(text: skill.name, systemImage: "checkmark.circle.fill", tint: .csSuccess)
                }
            }
        }
    }

    // MARK: - No goal

    private var noGoalCard: some View {
        EmptyStateView(
            systemImage: "target",
            title: "No target role yet",
            message: "Choose a career goal in the Roadmap tab and we'll build your personalised path.",
            actionTitle: "Choose a Role"
        ) {
            router.switchTo(.roadmap)
        }
        .csCard(padding: DesignSystem.Spacing.xs)
    }
}

// MARK: - Recommendation card component

struct RecommendationCard: View {
    let recommendation: SkillRecommendation
    let title: String
    let onStart: () -> Void
    let openSkill: (String) -> Void

    @State private var showsReasons = false

    init(
        recommendation: SkillRecommendation,
        title: String,
        onStart: @escaping () -> Void,
        openSkill: @escaping (String) -> Void
    ) {
        self.recommendation = recommendation
        self.title = title
        self.onStart = onStart
        self.openSkill = openSkill
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                Spacer()
                if let days = recommendation.estimatedDays {
                    ChipView(text: "~\(days) days", systemImage: "clock")
                }
            }

            Text("Learn \(recommendation.skill.name) next")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showsReasons.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(showsReasons ? "Hide details" : "Why this skill?")
                        .font(.caption.weight(.medium))
                    Image(systemName: showsReasons ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)

            if showsReasons {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(recommendation.reasons, id: \.self) { reason in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(Color.csSuccess)
                                .padding(.top, 2)
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(Color.csSecondaryText)
                        }
                    }
                    if !recommendation.unlockedSkillNames.isEmpty {
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "lock.open")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                                .padding(.top, 2)
                            Text("Unlocks: \(recommendation.unlockedSkillNames.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(Color.csSecondaryText)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Button("Start Learning") { onStart() }
                    .buttonStyle(.primary)
                    .accessibilityIdentifier("dashboard.startRecommended")
                Button("Details") { openSkill(recommendation.skill.id) }
                    .buttonStyle(.bordered)
            }
        }
        .csCard()
    }
}

// MARK: - Weekly chart

struct WeeklyActivityChart: View {
    let days: [ActivityService.DayActivity]

    var body: some View {
        Chart(days) { day in
            BarMark(
                x: .value("Day", day.date, unit: .day),
                y: .value("Minutes", day.minutes)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    .font(.caption2)
            }
        }
        .chartYAxis(.hidden)
        .accessibilityLabel("Learning minutes per day this week")
    }
}

// MARK: - Log session sheet

struct LogSessionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var minutes = 30

    private let presets = [15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("How long did you learn today?")
                    .font(.headline)
                FlowLayout(spacing: DesignSystem.Spacing.xs) {
                    ForEach(presets, id: \.self) { preset in
                        Button("\(preset)m") {
                            minutes = preset
                        }
                        .buttonStyle(.bordered)
                        .tint(minutes == preset ? .accentColor : Color.csSecondaryText)
                    }
                }
                Text("\(minutes) minutes")
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Log Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        PersistenceService.logLearningSession(minutes: minutes, skillSlug: nil, in: context)
                        try? context.save()
                        WidgetSnapshotPublisher.publish(context: context)
                        dismiss()
                    }
                    .accessibilityIdentifier("logSession.save")
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}
