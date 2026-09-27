import Foundation
import SwiftData
import Observation

/// Presentation model for the roadmap screen: grouping, filtering and search.
@Observable
final class RoadmapViewModel {
    enum NodeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case remaining = "Remaining"
        case completed = "Completed"

        var id: String { rawValue }
    }

    var searchText: String = ""
    var filter: NodeFilter = .all
    var expandedStages: Set<RoadmapStage> = Set(RoadmapStage.allCases)

    struct Item: Identifiable {
        let node: RoadmapNode
        let skill: Skill
        let state: RoadmapService.NodeState
        var id: String { skill.slug }
    }

    struct Section: Identifiable {
        let stage: RoadmapStage
        let items: [Item]
        let completedCount: Int
        var id: Int { stage.rawValue }
    }

    /// Groups a role's nodes into stages, applying search and filter.
    func sections(for role: CareerRole, context: ModelContext) -> [Section] {
        let service = RoadmapService(context: context)
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        var grouped: [RoadmapStage: [Item]] = [:]

        for node in role.orderedNodes {
            guard let skill = node.skill else { continue }
            let state = service.nodeState(for: skill, in: role)

            switch filter {
            case .remaining:
                if state == .completed { continue }
            case .completed:
                if state != .completed { continue }
            case .all:
                break
            }
            if !query.isEmpty && !skill.name.lowercased().contains(query) {
                continue
            }
            grouped[node.stage, default: []].append(Item(node: node, skill: skill, state: state))
        }

        return RoadmapStage.allCases.compactMap { stage in
            guard let items = grouped[stage], !items.isEmpty else { return nil }
            return Section(
                stage: stage,
                items: items,
                completedCount: items.filter { $0.state == .completed }.count
            )
        }
    }

    func toggleStage(_ stage: RoadmapStage) {
        if expandedStages.contains(stage) {
            expandedStages.remove(stage)
        } else {
            expandedStages.insert(stage)
        }
    }

    /// One-line status for the roadmap header.
    func headline(for role: CareerRole, context: ModelContext) -> String {
        let summary = RoadmapService(context: context).progressSummary(for: role)
        return "\(summary.requiredCompleted) of \(summary.requiredTotal) skills complete"
    }

    func levelForSkill(_ skill: Skill, context: ModelContext) -> Int {
        RoadmapService(context: context).userLevels()[skill.slug] ?? 0
    }

    func isExpanded(_ stage: RoadmapStage) -> Bool {
        expandedStages.contains(stage)
    }
}
