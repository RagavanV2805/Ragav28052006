import XCTest
import SwiftData
@testable import CareerOS

final class PrerequisiteResolutionTests: XCTestCase {

    func testCataloguePassesReferentialIntegrity() throws {
        // Throws on unknown slugs or duplicates.
        try SeedService.validate()
    }

    func testCataloguePrerequisiteGraphIsAcyclic() throws {
        try SeedService.validateAcyclic()
    }

    func testSeededPrerequisiteEdgesExist() throws {
        let container = try TestStore.makeContainer()
        let context = container.mainContext

        let algorithms = try XCTUnwrap(PersistenceService.skill(slug: "algorithms", in: context))
        let prereqSlugs = Set(algorithms.requiredPrerequisites.map(\.slug))
        XCTAssertTrue(prereqSlugs.contains("data-structures"))
        XCTAssertTrue(prereqSlugs.contains("complexity-analysis"))
    }

    func testUnlocksIsInverseOfPrerequisites() throws {
        let container = try TestStore.makeContainer()
        let context = container.mainContext

        let dataStructures = try XCTUnwrap(PersistenceService.skill(slug: "data-structures", in: context))
        let unlockedSlugs = Set(dataStructures.unlocks.map(\.slug))
        XCTAssertTrue(unlockedSlugs.contains("algorithms"),
                      "Data Structures must list Algorithms among the skills it unlocks")
    }

    func testOptionalPrerequisiteDoesNotLock() throws {
        // mlops has docker as an *optional* prerequisite. With machine-learning
        // satisfied and docker unsatisfied, mlops must not be locked.
        let container = try TestStore.makeContainer()
        let context = container.mainContext

        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = "ml-engineer"
        try context.save()
        let role = try XCTUnwrap(PersistenceService.role(slug: "ml-engineer", in: context))

        for slug in ["python", "statistics", "sql", "numpy", "pandas", "machine-learning"] {
            let progress = PersistenceService.skillProgress(forSkillSlug: slug, in: context)
            progress.level = 5
            progress.status = .completed
        }
        try context.save()

        let mlops = try XCTUnwrap(PersistenceService.skill(slug: "mlops", in: context))
        let state = RoadmapService(context: context).nodeState(for: mlops, in: role)
        XCTAssertEqual(state, .available, "Optional prerequisites must not lock a skill")
    }

    func testLockedNodeNotRecommended() throws {
        let container = try TestStore.makeContainer()
        let context = container.mainContext

        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = "software-engineer"
        try context.save()
        let role = try XCTUnwrap(PersistenceService.role(slug: "software-engineer", in: context))

        let plan = RoadmapService(context: context).learningPlan(for: role)
        let primaryID = try XCTUnwrap(plan.primary?.skill.id)

        // The recommended skill must have all its prerequisites satisfied.
        let recommended = try XCTUnwrap(PersistenceService.skill(slug: primaryID, in: context))
        let satisfied = RoadmapService(context: context).satisfiedSkillSlugs()
        for prereq in recommended.requiredPrerequisites {
            XCTAssertTrue(satisfied.contains(prereq.slug),
                          "Recommended \(primaryID) before prerequisite \(prereq.slug)")
        }
        _ = role
    }
}
