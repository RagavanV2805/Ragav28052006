import SwiftUI
import SwiftData

/// Projects hub: saved projects with filters, plus role-aware recommendations.
struct ProjectsListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ProjectsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                filters
                savedSection
                recommendedSection
                upcomingSection
            }
            .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle("Projects")
        .background(Color.csBackground)
        .searchable(text: $viewModel.searchText, prompt: "Search projects or technologies")
    }

    private var filters: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Picker("Status", selection: $viewModel.statusFilter) {
                ForEach(ProjectsViewModel.StatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    difficultyChip(nil, title: "All Levels")
                    ForEach(ProjectDifficulty.allCases) { difficulty in
                        difficultyChip(difficulty, title: difficulty.displayName)
                    }
                }
            }
        }
    }

    private func difficultyChip(_ difficulty: ProjectDifficulty?, title: String) -> some View {
        let isSelected = viewModel.difficultyFilter == difficulty
        return Button {
            viewModel.difficultyFilter = difficulty
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.csCard, in: Capsule())
                .foregroundStyle(isSelected ? .white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Saved

    @ViewBuilder
    private var savedSection: some View {
        SectionHeader(title: "Your Projects")
        let items = viewModel.savedItems(context: context)
        if items.isEmpty {
            EmptyStateView(
                systemImage: "hammer",
                title: viewModel.searchText.isEmpty ? "No projects yet" : "No matches",
                message: viewModel.searchText.isEmpty
                    ? "Start a recommended project below — building is how skills become real."
                    : "No saved projects match your search and filters."
            )
            .background(Color.csCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
        } else {
            ForEach(items) { item in
                NavigationLink(value: item.project) {
                    ProjectCard(project: item.project, status: item.status, fraction: item.fraction)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("project.saved.\(item.project.slug)")
            }
        }
    }

    // MARK: - Recommended

    @ViewBuilder
    private var recommendedSection: some View {
        let recommended = viewModel.recommended(context: context)
        if !recommended.isEmpty {
            SectionHeader(
                title: "Recommended for You",
                subtitle: "You have the required skills for these"
            )
            ForEach(recommended.prefix(5)) { project in
                VStack(spacing: DesignSystem.Spacing.xs) {
                    NavigationLink(value: project) {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                    Button {
                        viewModel.start(project, context: context)
                        router.openProject(project)
                    } label: {
                        Label("Start This Project", systemImage: "play.fill")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Upcoming

    @ViewBuilder
    private var upcomingSection: some View {
        let upcoming = viewModel.upcoming(context: context)
        if !upcoming.isEmpty {
            SectionHeader(
                title: "Almost Ready",
                subtitle: "Finish a few more skills to unlock these"
            )
            ForEach(upcoming) { project in
                NavigationLink(value: project) {
                    ProjectCard(project: project)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(Color.csLocked)
                                .padding(DesignSystem.Spacing.xs)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
