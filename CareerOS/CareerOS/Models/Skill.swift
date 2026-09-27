import Foundation
import SwiftData

/// A single learnable skill. Skills are **global** — they are shared across
/// career roles and wired into each role through `RoadmapNode`. Prerequisite
/// edges form a directed acyclic graph via `SkillPrerequisite`.
@Model
final class Skill {
    /// Stable slug used as the join key for seed data and progress records.
    @Attribute(.unique) var slug: String
    var name: String
    var summary: String
    var categoryRaw: String
    /// Rough guided-learning effort in hours.
    var estimatedHours: Double
    /// Populated by `SeedService`; keeps first launch deterministic.
    var seededAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SkillPrerequisite.skill)
    var prerequisiteEdges: [SkillPrerequisite] = []

    @Relationship(deleteRule: .cascade, inverse: \SkillPrerequisite.prerequisite)
    var dependentEdges: [SkillPrerequisite] = []

    @Relationship(deleteRule: .cascade, inverse: \Resource.skill)
    var resources: [Resource] = []

    @Relationship(deleteRule: .cascade, inverse: \SkillProgress.skill)
    var progress: SkillProgress?

    @Relationship(deleteRule: .cascade, inverse: \RoadmapNode.skill)
    var roadmapNodes: [RoadmapNode] = []

    @Relationship(inverse: \Project.requiredSkills)
    var projectsRequiring: [Project] = []

    @Relationship(inverse: \Project.optionalSkills)
    var projectsSuggesting: [Project] = []

    init(
        slug: String,
        name: String,
        summary: String,
        category: SkillCategory,
        estimatedHours: Double,
        seededAt: Date = .now
    ) {
        self.slug = slug
        self.name = name
        self.summary = summary
        self.categoryRaw = category.rawValue
        self.estimatedHours = estimatedHours
        self.seededAt = seededAt
    }

    var category: SkillCategory {
        get { SkillCategory(rawValue: categoryRaw) ?? .fundamentals }
        set { categoryRaw = newValue.rawValue }
    }

    /// Skills that must (or should) be learned before this one.
    var prerequisites: [Skill] {
        prerequisiteEdges
            .sorted { lhs, rhs in
                if lhs.isRequired != rhs.isRequired { return lhs.isRequired }
                return (lhs.prerequisite?.name ?? "") < (rhs.prerequisite?.name ?? "")
            }
            .compactMap(\.prerequisite)
    }

    var requiredPrerequisites: [Skill] {
        prerequisiteEdges.filter(\.isRequired).compactMap(\.prerequisite)
    }

    /// Skills for which this skill is a prerequisite.
    var unlocks: [Skill] {
        dependentEdges
            .compactMap(\.skill)
            .sorted { $0.name < $1.name }
    }
}

/// Explicit prerequisite edge between two skills, allowing edges to carry
/// metadata (`isRequired`) instead of an opaque many-to-many set.
@Model
final class SkillPrerequisite {
    var isRequired: Bool
    var skill: Skill?
    var prerequisite: Skill?

    init(skill: Skill, prerequisite: Skill, isRequired: Bool = true) {
        self.skill = skill
        self.prerequisite = prerequisite
        self.isRequired = isRequired
    }
}
