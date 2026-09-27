import Foundation
import SwiftData
import Observation

@Observable
final class ProjectsViewModel {
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case inProgress = "In Progress"
        case paused = "Paused"
        case completed = "Completed"

        var id: String { rawValue }
    }

    var searchText: String = ""
    var statusFilter: StatusFilter = .all
    var difficultyFilter: ProjectDifficulty? = nil

    struct ListItem: Identifiable {
        let project: Project
        let status: ProjectStatus
        let fraction: Double
        var id: String { project.slug }
    }

    /// Saved projects (any progress record exists), filtered and searched.
    func savedItems(context: ModelContext) -> [ListItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let records = PersistenceService.fetchAll(ProjectProgress.self, in: context)
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }

        return records.compactMap { record in
            guard let project = record.project else { return nil }
            if statusFilter != .all && record.status != statusFilter.projectStatus { return nil }
            if let difficultyFilter, project.difficulty != difficultyFilter { return nil }
            if !query.isEmpty
                && !project.title.lowercased().contains(query)
                && !project.technologyStack.joined(separator: " ").lowercased().contains(query) {
                return nil
            }
            return ListItem(project: project, status: record.status, fraction: project.milestoneFraction)
        }
    }

    /// Projects recommended for the target role whose required skills are met.
    func recommended(context: ModelContext) -> [Project] {
        guard let role = RoadmapService(context: context).targetRole() else { return [] }
        let service = RoadmapService(context: context)
        var projects = service.recommendedProjects(for: role)
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            projects = projects.filter { $0.title.lowercased().contains(query) }
        }
        if let difficultyFilter {
            projects = projects.filter { $0.difficulty == difficultyFilter }
        }
        return projects
    }

    /// Almost-ready projects, sorted by readiness.
    func upcoming(context: ModelContext) -> [Project] {
        guard let role = RoadmapService(context: context).targetRole() else { return [] }
        let service = RoadmapService(context: context)
        var projects = service.upcomingProjects(for: role)
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            projects = projects.filter { $0.title.lowercased().contains(query) }
        }
        return Array(projects.prefix(6))
    }

    // MARK: - Actions

    func start(_ project: Project, context: ModelContext) {
        let progress = PersistenceService.projectProgress(forProjectSlug: project.slug, in: context)
        progress.status = .inProgress
        progress.startedAt = .now
        try? context.save()
        WidgetSnapshotPublisher.publish(context: context)
    }
}

private extension ProjectsViewModel.StatusFilter {
    var projectStatus: ProjectStatus? {
        switch self {
        case .all: return nil
        case .inProgress: return .inProgress
        case .paused: return .paused
        case .completed: return .completed
        }
    }
}
