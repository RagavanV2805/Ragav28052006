import Foundation
import SwiftData

/// A supported career goal (e.g. "iOS Developer"). Adding a new role is a
/// data-only change: append a `RoleSeed` entry and re-seed.
@Model
final class CareerRole {
    @Attribute(.unique) var slug: String
    var name: String
    var tagline: String
    var summary: String
    var iconName: String
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Roadmap.role)
    var roadmap: Roadmap?

    @Relationship(deleteRule: .cascade, inverse: \RoadmapNode.role)
    var directNodes: [RoadmapNode] = []

    @Relationship(inverse: \Project.roles)
    var projects: [Project] = []

    init(
        slug: String,
        name: String,
        tagline: String,
        summary: String,
        iconName: String,
        sortOrder: Int
    ) {
        self.slug = slug
        self.name = name
        self.tagline = tagline
        self.summary = summary
        self.iconName = iconName
        self.sortOrder = sortOrder
    }

    /// Nodes of the role's roadmap sorted by stage then learning order.
    var orderedNodes: [RoadmapNode] {
        (roadmap?.nodes ?? []).sorted { lhs, rhs in
            if lhs.stageRaw != rhs.stageRaw { return lhs.stageRaw < rhs.stageRaw }
            return lhs.orderIndex < rhs.orderIndex
        }
    }

    var requiredNodes: [RoadmapNode] { orderedNodes.filter { !$0.isOptional } }
}

/// One roadmap per role; owns its nodes. Kept as a distinct model so a role
/// could support alternate roadmap versions in the future.
@Model
final class Roadmap {
    var name: String
    var role: CareerRole?

    @Relationship(deleteRule: .cascade, inverse: \RoadmapNode.roadmap)
    var nodes: [RoadmapNode] = []

    init(name: String) {
        self.name = name
    }
}

/// Role-specific placement of a global `Skill`: which stage it belongs to,
/// how important it is for this role, whether it is optional and the level
/// the user should aim for.
@Model
final class RoadmapNode {
    var stageRaw: Int
    var orderIndex: Int
    /// 1 (nice to have) ... 5 (essential).
    var importance: Int
    var isOptional: Bool
    /// Target self-rating for the role (0...5).
    var targetLevel: Int
    var skill: Skill?
    var roadmap: Roadmap?
    var role: CareerRole?

    init(
        stage: RoadmapStage,
        orderIndex: Int,
        importance: Int,
        isOptional: Bool = false,
        targetLevel: Int = 3,
        skill: Skill? = nil
    ) {
        self.stageRaw = stage.rawValue
        self.orderIndex = orderIndex
        self.importance = importance
        self.isOptional = isOptional
        self.targetLevel = targetLevel
        self.skill = skill
    }

    var stage: RoadmapStage {
        get { RoadmapStage(rawValue: stageRaw) ?? .fundamentals }
        set { stageRaw = newValue.rawValue }
    }
}
