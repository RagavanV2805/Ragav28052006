import Foundation
import SwiftData

/// Bridges SwiftData models to the pure planning engines. ViewModels call
/// this service and never talk to the engines with model objects directly.
struct RoadmapService {
    let context: ModelContext

    private let engine = RecommendationEngine()
    private let progressCalculator = RoadmapProgressCalculator()
    private let matchCalculator = RoleMatchCalculator()
    private let projectEligibility = ProjectEligibilityCalculator()

    // MARK: - Lookups

    func allRoles() -> [CareerRole] {
        PersistenceService.fetchAll(
            CareerRole.self, in: context,
            sortBy: [SortDescriptor(\.sortOrder)]
        )
    }

    func targetRole() -> CareerRole? {
        guard let slug = PersistenceService.profile(in: context).targetRoleSlug else { return nil }
        return PersistenceService.role(slug: slug, in: context)
    }

    // MARK: - User state maps

    /// Current self-ratings keyed by skill slug.
    func userLevels() -> [String: Int] {
        Dictionary(
            PersistenceService.fetchAll(SkillProgress.self, in: context)
                .map { ($0.skillSlug, $0.level) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func completedSkillSlugs() -> Set<String> {
        Set(
            PersistenceService.fetchAll(SkillProgress.self, in: context)
                .filter { $0.status == .completed }
                .map(\.skillSlug)
        )
    }

    func inProgressSkillSlugs() -> Set<String> {
        Set(
            PersistenceService.fetchAll(SkillProgress.self, in: context)
                .filter { $0.status == .inProgress }
                .map(\.skillSlug)
        )
    }

    /// Skills satisfied anywhere (any role) — completed, or rated
    /// intermediate-or-better. Feeds the engine so previous progress keeps
    /// counting after a role switch.
    func satisfiedSkillSlugs() -> Set<String> {
        Set(
            PersistenceService.fetchAll(SkillProgress.self, in: context)
                .filter(\.isSatisfied)
                .map(\.skillSlug)
        )
    }

    // MARK: - Snapshots for engines

    func plannerSkills(for role: CareerRole) -> [PlannerSkill] {
        let levels = userLevels()
        let completed = completedSkillSlugs()
        let inProgress = inProgressSkillSlugs()

        return role.orderedNodes.compactMap { node in
            guard let skill = node.skill else { return nil }
            return PlannerSkill(
                id: skill.slug,
                name: skill.name,
                stageIndex: node.stageRaw,
                importance: node.importance,
                isOptional: node.isOptional,
                targetLevel: node.targetLevel,
                estimatedHours: skill.estimatedHours,
                requiredPrerequisiteIDs: skill.requiredPrerequisites.map(\.slug),
                userLevel: levels[skill.slug] ?? 0,
                isCompleted: completed.contains(skill.slug),
                isInProgress: inProgress.contains(skill.slug)
            )
        }
    }

    func requirementSnapshots() -> [RoleRequirementSnapshot] {
        allRoles().map { role in
            RoleRequirementSnapshot(
                roleSlug: role.slug,
                roleName: role.name,
                iconName: role.iconName,
                nodes: role.orderedNodes.compactMap { node in
                    guard let skill = node.skill else { return nil }
                    return RoleRequirementSnapshot.Node(
                        skillID: skill.slug,
                        skillName: skill.name,
                        importance: node.importance,
                        targetLevel: node.targetLevel,
                        isOptional: node.isOptional
                    )
                }
            )
        }
    }

    // MARK: - Computations

    func progressSummary(for role: CareerRole) -> RoadmapProgressSummary {
        let levels = userLevels()
        let completed = completedSkillSlugs()
        let nodes = role.orderedNodes.compactMap { node -> RoadmapProgressCalculator.NodeState? in
            guard let skill = node.skill else { return nil }
            let level = levels[skill.slug] ?? 0
            let met = completed.contains(skill.slug) || level >= node.targetLevel
            return RoadmapProgressCalculator.NodeState(
                stageIndex: node.stageRaw,
                importance: node.importance,
                isOptional: node.isOptional,
                isMet: met
            )
        }
        return progressCalculator.summary(for: nodes)
    }

    func learningPlan(for role: CareerRole) -> LearningPlan {
        engine.plan(
            skills: plannerSkills(for: role),
            satisfiedExternalIDs: satisfiedSkillSlugs(),
            dailyMinutes: PersistenceService.profile(in: context).dailyMinutes
        )
    }

    func roleMatches() -> [RoleMatch] {
        matchCalculator.matches(
            for: requirementSnapshots(),
            levels: userLevels(),
            completedIDs: completedSkillSlugs(),
            inProgressIDs: inProgressSkillSlugs()
        )
    }

    // MARK: - Node presentation state

    enum NodeState: Equatable {
        case locked      // a required prerequisite is not met yet
        case available   // ready to start
        case inProgress
        case completed
    }

    /// Presentation state of a single roadmap node. A node is locked when any
    /// required prerequisite is unsatisfied — skills are never recommended
    /// ahead of their important prerequisites.
    func nodeState(for skill: Skill, in role: CareerRole) -> NodeState {
        nodeState(for: skill)
    }

    /// Role-independent variant (prerequisite satisfaction is global).
    func nodeState(for skill: Skill) -> NodeState {
        let satisfied = satisfiedSkillSlugs()
        if satisfied.contains(skill.slug) {
            let inProgress = inProgressSkillSlugs()
            return inProgress.contains(skill.slug) ? .inProgress : .completed
        }
        let blockers = skill.requiredPrerequisites.filter { !satisfied.contains($0.slug) }
        return blockers.isEmpty ? .available : .locked
    }

    /// Projects whose required skills are all satisfied, for a role.
    func recommendedProjects(for role: CareerRole) -> [Project] {
        let satisfied = satisfiedSkillSlugs()
        let startedSlugs = Set(
            PersistenceService.fetchAll(ProjectProgress.self, in: context).map(\.projectSlug)
        )
        return role.projects
            .filter { !startedSlugs.contains($0.slug) }
            .filter { project in
                projectEligibility.isEligible(
                    requiredSkillIDs: project.requiredSkills.map(\.slug),
                    satisfiedIDs: satisfied
                )
            }
            .sorted { $0.difficulty.sortOrder < $1.difficulty.sortOrder }
    }

    /// Projects almost ready — sorted by readiness for "up next" surfaces.
    func upcomingProjects(for role: CareerRole) -> [Project] {
        let satisfied = satisfiedSkillSlugs()
        let startedSlugs = Set(
            PersistenceService.fetchAll(ProjectProgress.self, in: context).map(\.projectSlug)
        )
        return role.projects
            .filter { !startedSlugs.contains($0.slug) }
            .filter { project in
                !projectEligibility.isEligible(
                    requiredSkillIDs: project.requiredSkills.map(\.slug),
                    satisfiedIDs: satisfied
                )
            }
            .sorted { lhs, rhs in
                projectEligibility.readiness(requiredSkillIDs: lhs.requiredSkills.map(\.slug), satisfiedIDs: satisfied)
                    > projectEligibility.readiness(requiredSkillIDs: rhs.requiredSkills.map(\.slug), satisfiedIDs: satisfied)
            }
    }
}
