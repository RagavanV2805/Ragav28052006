import XCTest
import SwiftData
@testable import CareerOS

final class SkillCompletionTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try TestStore.makeContainer()
        context = container.mainContext
    }

    private func targetRole() -> CareerRole {
        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = "software-engineer"
        let role = PersistenceService.role(slug: "software-engineer", in: context)
        XCTAssertNotNil(role)
        return role!
    }

    func testMarkCompleteSetsStatusAndLevel() throws {
        let skill = try XCTUnwrap(PersistenceService.skill(slug: "git-version-control", in: context))
        let viewModel = SkillDetailViewModel(skill: skill)
        viewModel.load(context: context)

        viewModel.markComplete(context: context)

        let progress = try XCTUnwrap(PersistenceService.skillProgress(forSkillSlug: skill.slug, in: context))
        XCTAssertEqual(progress.status, .completed)
        XCTAssertNotNil(progress.completedAt)
        XCTAssertGreaterThanOrEqual(progress.level, SkillLevel.intermediate.rawValue)
    }

    func testCompletedSkillSatisfiesDependents() throws {
        // "algorithms" requires data-structures + complexity-analysis.
        // Complete the prerequisites and verify algorithms becomes available.
        let role = targetRole()
        let service = RoadmapService(context: context)

        let algorithms = try XCTUnwrap(PersistenceService.skill(slug: "algorithms", in: context))
        XCTAssertEqual(service.nodeState(for: algorithms, in: role), .locked,
                       "Algorithms must start locked without prerequisites")

        for slug in ["data-structures", "complexity-analysis", "programming-fundamentals"] {
            let progress = PersistenceService.skillProgress(forSkillSlug: slug, in: context)
            progress.level = 5
            progress.status = .completed
        }
        try context.save()

        XCTAssertEqual(service.nodeState(for: algorithms, in: role), .available,
                       "Completing all prerequisites must unlock the skill")
    }

    func testHighLevelAloneSatisfiesSkill() {
        // Rating intermediate without pressing "complete" still counts.
        let progress = PersistenceService.skillProgress(forSkillSlug: "programming-fundamentals", in: context)
        progress.level = SkillLevel.intermediate.rawValue
        try? context.save()

        let satisfied = RoadmapService(context: context).satisfiedSkillSlugs()
        XCTAssertTrue(satisfied.contains("programming-fundamentals"))
    }

    func testCompletionCountsInRoadmapProgress() throws {
        let role = targetRole()
        let before = RoadmapService(context: context).progressSummary(for: role)

        let progress = PersistenceService.skillProgress(forSkillSlug: "git-version-control", in: context)
        progress.level = 5
        progress.status = .completed
        try context.save()

        let after = RoadmapService(context: context).progressSummary(for: role)
        XCTAssertGreaterThan(after.overallFraction, before.overallFraction)
        XCTAssertEqual(after.requiredCompleted, before.requiredCompleted + 1)
    }

    func testRoleSwitchPreservesProgress() throws {
        // Complete a skill under one role…
        let progress = PersistenceService.skillProgress(forSkillSlug: "git-version-control", in: context)
        progress.level = 5
        progress.status = .completed
        try context.save()

        // …then switch roles.
        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = "full-stack-developer"
        try context.save()

        let still = PersistenceService.skillProgress(forSkillSlug: "git-version-control", in: context)
        XCTAssertEqual(still.status, .completed, "Progress must survive a role change")

        let satisfied = RoadmapService(context: context).satisfiedSkillSlugs()
        XCTAssertTrue(satisfied.contains("git-version-control"))
    }

    func testRecommendationSkipsCompletedSkills() throws {
        let role = targetRole()
        let service = RoadmapService(context: context)

        // Complete programming fundamentals so the plan moves on.
        let progress = PersistenceService.skillProgress(forSkillSlug: "programming-fundamentals", in: context)
        progress.level = 5
        progress.status = .completed
        try context.save()

        let plan = service.learningPlan(for: role)
        XCTAssertNotEqual(plan.primary?.skill.id, "programming-fundamentals")
        XCTAssertNotNil(plan.primary, "A seeded role should always have a next step")
    }
}
