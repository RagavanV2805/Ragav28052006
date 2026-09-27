import Foundation

/// Value types describing the bundled catalogue. `SeedService` converts these
/// into SwiftData models on first launch. Adding a role, skill or project is
/// a pure data change — no UI or logic edits required.

struct ResourceSeed {
    let kind: ResourceKind
    let title: String
    let author: String
    let url: String
    let isFree: Bool

    static func r(
        _ kind: ResourceKind,
        _ title: String,
        _ author: String = "",
        _ url: String,
        free: Bool = true
    ) -> ResourceSeed {
        ResourceSeed(kind: kind, title: title, author: author, url: url, isFree: free)
    }
}

struct SkillSeed {
    let slug: String
    let name: String
    let summary: String
    let category: SkillCategory
    let estimatedHours: Double
    /// Required prerequisite slugs.
    let prereqs: [String]
    /// Recommended-but-not-blocking prerequisite slugs.
    let optionalPrereqs: [String]
    let resources: [ResourceSeed]

    static func s(
        _ slug: String,
        _ name: String,
        _ summary: String,
        _ category: SkillCategory,
        _ hours: Double,
        prereqs: [String] = [],
        optionalPrereqs: [String] = [],
        res: [ResourceSeed] = []
    ) -> SkillSeed {
        SkillSeed(
            slug: slug,
            name: name,
            summary: summary,
            category: category,
            estimatedHours: hours,
            prereqs: prereqs,
            optionalPrereqs: optionalPrereqs,
            resources: res
        )
    }
}

struct RoleNodeSeed {
    let skillSlug: String
    let stage: RoadmapStage
    let importance: Int
    let isOptional: Bool
    let targetLevel: Int

    init(
        _ skillSlug: String,
        _ stage: RoadmapStage,
        _ importance: Int,
        optional: Bool = false,
        target: Int = 3
    ) {
        self.skillSlug = skillSlug
        self.stage = stage
        self.importance = importance
        self.isOptional = optional
        self.targetLevel = target
    }
}

struct MilestoneSeed {
    let title: String

    init(_ title: String) { self.title = title }
}

struct ProjectSeed {
    let slug: String
    let title: String
    let summary: String
    let difficulty: ProjectDifficulty
    let estimatedWeeks: Int
    let stack: [String]
    let outcomes: [String]
    let requiredSkillSlugs: [String]
    let optionalSkillSlugs: [String]
    let milestones: [MilestoneSeed]
    let roleSlugs: [String]

    static func p(
        _ slug: String,
        _ title: String,
        _ summary: String,
        difficulty: ProjectDifficulty,
        weeks: Int,
        stack: [String],
        outcomes: [String],
        required: [String],
        optional: [String] = [],
        milestones: [MilestoneSeed],
        roles: [String]
    ) -> ProjectSeed {
        ProjectSeed(
            slug: slug,
            title: title,
            summary: summary,
            difficulty: difficulty,
            estimatedWeeks: weeks,
            stack: stack,
            outcomes: outcomes,
            requiredSkillSlugs: required,
            optionalSkillSlugs: optional,
            milestones: milestones,
            roleSlugs: roles
        )
    }
}

struct RoleSeed {
    let slug: String
    let name: String
    let tagline: String
    let summary: String
    let iconName: String
    let nodes: [RoleNodeSeed]
    /// Order in the role catalogue.
    let sortOrder: Int
}
