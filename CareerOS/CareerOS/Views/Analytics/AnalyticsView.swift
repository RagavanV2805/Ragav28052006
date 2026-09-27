import SwiftUI
import SwiftData
import Charts

/// Progress analytics: meaningful charts tied to real learning evidence.
struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        StateView(state: viewModel.state, retry: {
            Task { await viewModel.load(context: context) }
        }) { data in
            analyticsContent(data)
        }
        .navigationTitle("Analytics")
        .background(Color.csBackground)
        .task { await viewModel.load(context: context) }
        .refreshable { await viewModel.load(context: context) }
    }

    @ViewBuilder
    private func analyticsContent(_ data: AnalyticsData) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                statsGrid(data)
                weeklyChart(data)
                progressChart(data)
                categoryChart(data)
                footnote
            }
            .padding(DesignSystem.Spacing.md)
        }
    }

    private func statsGrid(_ data: AnalyticsData) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
            StatTile(title: "Roadmap", value: "\(data.overallPercent)%", systemImage: "map", tint: .accentColor)
            StatTile(title: "Streak", value: "\(data.streakLength) days", systemImage: "flame.fill", tint: .orange)
            StatTile(title: "Skills Done", value: "\(data.skillsCompleted)", systemImage: "checkmark.circle.fill", tint: .csSuccess)
            StatTile(title: "Projects Done", value: "\(data.projectsCompleted)", systemImage: "hammer.fill", tint: .purple)
        }
        .accessibilityIdentifier("analytics.statsGrid")
    }

    // MARK: - Weekly activity

    private func weeklyChart(_ data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Weekly Learning Activity", subtitle: "Minutes logged per day")
            Chart(data.weeklyActivity) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
        .csCard()
        .accessibilityLabel("Bar chart of daily learning minutes for the last week")
    }

    // MARK: - Progress over time

    private func progressChart(_ data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            SectionHeader(title: "Skills Completed Over Time", subtitle: "Last 12 weeks")
            if data.progressOverTime.allSatisfy({ $0.completedSkills == 0 }) {
                EmptyStateView(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: "No completions yet",
                    message: "Complete skills from your roadmap and this line will start climbing."
                )
            } else {
                Chart(data.progressOverTime) { point in
                    LineMark(
                        x: .value("Week", point.date),
                        y: .value("Completed", point.completedSkills)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value("Week", point.date),
                        y: .value("Completed", point.completedSkills)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor.opacity(0.12))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 3)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 180)
            }
        }
        .csCard()
        .accessibilityLabel("Line chart of cumulative completed skills")
    }

    // MARK: - Category breakdown

    @ViewBuilder
    private func categoryChart(_ data: AnalyticsData) -> some View {
        if !data.categoryBreakdown.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SectionHeader(title: "Progress by Category", subtitle: "Completion across your role's skill areas")
                Chart(data.categoryBreakdown) { slice in
                    BarMark(
                        x: .value("Completed", slice.completed),
                        y: .value("Category", slice.category.displayName)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .annotation(position: .trailing) {
                        Text("\(slice.completed)/\(slice.total)")
                            .font(.caption2)
                            .foregroundStyle(Color.csSecondaryText)
                    }
                }
                .frame(height: CGFloat(max(data.categoryBreakdown.count, 1)) * 44)
            }
            .csCard()
            .accessibilityLabel("Horizontal bar chart of completed skills per category")
        }
    }

    private var footnote: some View {
        Text("Time logged: \(viewModel.formattedTotalTime). Analytics come from sessions you log and skills you complete — everything stays on this device.")
            .font(.caption2)
            .foregroundStyle(Color.csSecondaryText)
    }
}
