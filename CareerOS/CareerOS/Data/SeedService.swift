import Foundation
import SwiftData

enum SeedError: Error, CustomStringConvertible {
    case duplicateSkillSlug(String)
    case duplicateProjectSlug(String)
    case unknownPrerequisite(skill: String, prerequisite: String)
    case unknownSkillInRole(role: String, skill: String)
    case unknownSkillInProject(project: String, skill: String)
    case unknownRoleForProject(project: String, role: String)
    case prerequisiteCycle([String])

    var description: String {
        switch self {
        case .duplicateSkillSlug(let slug): return "Duplicate skill slug: \(slug)"
        case .duplicateProjectSlug(let slug): return "Duplicate project slug: \(slug)"
        case .unknownPrerequisite(let skill, let prereq): return "Skill '\(skill)' references unknown prerequisite '\(prereq)'"
        case .unknownSkillInRole(let role, let skill): return "Role '\(role)' references unknown skill '\(skill)'"
        case .unknownSkillInProject(let project, let skill): return "Project '\(project)' references unknown skill '\(skill)'"
        case .unknownRoleForProject(let project, let role): return "Project '\(project)' references unknown role '\(role)'"
        case .prerequisiteCycle(let path): return "Prerequisite cycle detected: \(path.joined(separator: " → "))"
        }
    }
}

/// Converts the bundled catalogue into SwiftData models on first launch and
/// validates the data graph before inserting anything.
enum SeedService {

    static func seedIfNeeded(context: ModelContext) throws {
        var probe = FetchDescriptor<CareerRole>()
        probe.fetchLimit = 1
        let alreadySeeded = !(try context.fetch(probe)).isEmpty
        guard !alreadySeeded else { return }
        try seed(into: context)
    }

    /// Validates referential integrity and acyclicity of the prerequisite
    /// graph. Exposed so unit tests can guard the catalogue.
    static func validate() throws {
        var seenSlugs = Set<String>()
        for skill in SkillCatalogue.all {
            guard seenSlugs.insert(skill.slug).inserted else {
                throw SeedError.duplicateSkillSlug(skill.slug)
            }
        }
        let validSlugs = seenSlugs

        for skill in SkillCatalogue.all {
            for prereq in skill.prereqs + skill.optionalPrereqs where !validSlugs.contains(prereq) {
                throw SeedError.unknownPrerequisite(skill: skill.slug, prerequisite: prereq)
            }
        }

        var projectSlugs = Set<String>()
        let roleSlugs = Set(RoleCatalogue.all.map(\.slug))
        for project in ProjectCatalogue.all {
            guard projectSlugs.insert(project.slug).inserted else {
                throw SeedError.duplicateProjectSlug(project.slug)
            }
            for slug in project.requiredSkillSlugs + project.optionalSkillSlugs where !validSlugs.contains(slug) {
                throw SeedError.unknownSkillInProject(project: project.slug, skill: slug)
            }
            for slug in project.roleSlugs where !roleSlugs.contains(slug) {
                throw SeedError.unknownRoleForProject(project: project.slug, role: slug)
            }
        }

        for role in RoleCatalogue.all {
            for node in role.nodes where !validSlugs.contains(node.skillSlug) {
                throw SeedError.unknownSkillInRole(role: role.slug, skill: node.skillSlug)
            }
        }

        try validateAcyclic()
    }

    /// DFS cycle detection over the prerequisite graph.
    static func validateAcyclic() throws {
        let adjacency = Dictionary(
            SkillCatalogue.all.map { ($0.slug, $0.prereqs + $0.optionalPrereqs) },
            uniquingKeysWith: { first, _ in first }
        )
        var visiting = Set<String>()
        var visited = Set<String>()
        var path: [String] = []

        func visit(_ slug: String) throws {
            if visited.contains(slug) { return }
            if visiting.contains(slug) {
                throw SeedError.prerequisiteCycle(path + [slug])
            }
            visiting.insert(slug)
            path.append(slug)
            for next in adjacency[slug] ?? [] {
                try visit(next)
            }
            path.removeLast()
            visiting.remove(slug)
            visited.insert(slug)
        }

        for skill in SkillCatalogue.all {
            try visit(skill.slug)
        }
    }

    static func seed(into context: ModelContext) throws {
        try validate()

        // 1. Skills + resources.
        var skillsBySlug: [String: Skill] = [:]
        for seed in SkillCatalogue.all {
            let skill = Skill(
                slug: seed.slug,
                name: seed.name,
                summary: seed.summary,
                category: seed.category,
                estimatedHours: seed.estimatedHours
            )
            for resourceSeed in seed.resources {
                let resource = Resource(
                    kind: resourceSeed.kind,
                    title: resourceSeed.title,
                    author: resourceSeed.author,
                    urlString: resourceSeed.url,
                    isFree: resourceSeed.isFree
                )
                skill.resources.append(resource)
            }
            context.insert(skill)
            skillsBySlug[seed.slug] = skill
        }

        // 2. Prerequisite edges.
        for seed in SkillCatalogue.all {
            guard let skill = skillsBySlug[seed.slug] else { continue }
            for prereqSlug in seed.prereqs {
                guard let prereq = skillsBySlug[prereqSlug] else { continue }
                let edge = SkillPrerequisite(skill: skill, prerequisite: prereq, isRequired: true)
                context.insert(edge)
            }
            for prereqSlug in seed.optionalPrereqs {
                guard let prereq = skillsBySlug[prereqSlug] else { continue }
                let edge = SkillPrerequisite(skill: skill, prerequisite: prereq, isRequired: false)
                context.insert(edge)
            }
        }

        // 3. Roles, roadmaps and nodes.
        for roleSeed in RoleCatalogue.all {
            let role = CareerRole(
                slug: roleSeed.slug,
                name: roleSeed.name,
                tagline: roleSeed.tagline,
                summary: roleSeed.summary,
                iconName: roleSeed.iconName,
                sortOrder: roleSeed.sortOrder
            )
            let roadmap = Roadmap(name: "\(roleSeed.name) Roadmap")
            roadmap.role = role
            context.insert(role)
            context.insert(roadmap)

            for (index, nodeSeed) in roleSeed.nodes.enumerated() {
                guard let skill = skillsBySlug[nodeSeed.skillSlug] else { continue }
                let node = RoadmapNode(
                    stage: nodeSeed.stage,
                    orderIndex: index,
                    importance: nodeSeed.importance,
                    isOptional: nodeSeed.isOptional,
                    targetLevel: nodeSeed.targetLevel,
                    skill: skill
                )
                node.roadmap = roadmap
                node.role = role
                context.insert(node)
            }
        }

        // 4. Projects.
        for seed in ProjectCatalogue.all {
            let project = Project(
                slug: seed.slug,
                title: seed.title,
                summary: seed.summary,
                difficulty: seed.difficulty,
                estimatedWeeks: seed.estimatedWeeks,
                technologyStack: seed.stack,
                learningOutcomes: seed.outcomes
            )
            project.requiredSkills = seed.requiredSkillSlugs.compactMap { skillsBySlug[$0] }
            project.optionalSkills = seed.optionalSkillSlugs.compactMap { skillsBySlug[$0] }
            for (index, milestone) in seed.milestones.enumerated() {
                let model = ProjectMilestone(title: milestone.title, orderIndex: index)
                model.project = project
                context.insert(model)
            }
            context.insert(project)
        }

        // Link projects to roles after all projects exist.
        let projectsBySlug = Dictionary(
            uniqueKeysWithValues: fetchProjects(in: context).map { ($0.slug, $0) }
        )
        let rolesBySlug = Dictionary(
            uniqueKeysWithValues: fetchRoles(in: context).map { ($0.slug, $0) }
        )
        for seed in ProjectCatalogue.all {
            guard let project = projectsBySlug[seed.slug] else { continue }
            project.roles = seed.roleSlugs.compactMap { rolesBySlug[$0] }
        }

        try context.save()
    }

    /// Removes every user-generated record while keeping the seeded catalogue.
    /// Used by the "Reset progress" setting.
    static func resetUserProgress(in context: ModelContext) {
        for progress in PersistenceService.fetchAll(SkillProgress.self, in: context) {
            context.delete(progress)
        }
        for progress in PersistenceService.fetchAll(ProjectProgress.self, in: context) {
            context.delete(progress)
        }
        for session in PersistenceService.fetchAll(LearningSession.self, in: context) {
            context.delete(session)
        }
        for project in PersistenceService.fetchAll(Project.self, in: context) {
            for milestone in project.milestones {
                milestone.isDone = false
                milestone.completedAt = nil
            }
        }
        if let profile = PersistenceService.fetchOne(UserProfile.self, in: context) {
            profile.hasCompletedOnboarding = false
            profile.targetRoleSlug = nil
        }
        try? context.save()
    }

    private static func fetchProjects(in context: ModelContext) -> [Project] {
        (try? context.fetch(FetchDescriptor<Project>())) ?? []
    }

    private static func fetchRoles(in context: ModelContext) -> [CareerRole] {
        (try? context.fetch(FetchDescriptor<CareerRole>())) ?? []
    }
}
