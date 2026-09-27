import XCTest
import SwiftData
@testable import CareerOS

final class PersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try TestStore.makeContainer()
        context = container.mainContext
    }

    func testSeedingCreatesAllFourteenRoles() {
        let roles = PersistenceService.fetchAll(CareerRole.self, in: context)
        XCTAssertEqual(roles.count, 14)
    }

    func testSeedingCreatesEveryRoadmapNodeForEveryRole() {
        for role in PersistenceService.fetchAll(CareerRole.self, in: context) {
            XCTAssertFalse(role.orderedNodes.isEmpty, "\(role.slug) has no roadmap nodes")
            for node in role.orderedNodes {
                XCTAssertNotNil(node.skill, "\(role.slug) node missing skill")
            }
        }
    }

    func testSeedingIsIdempotent() throws {
        // Seeding twice must not duplicate roles.
        try SeedService.seedIfNeeded(context: context)
        let roles = PersistenceService.fetchAll(CareerRole.self, in: context)
        XCTAssertEqual(roles.count, 14)
    }

    func testSkillsHaveResources() {
        let skills = PersistenceService.fetchAll(Skill.self, in: context)
        XCTAssertFalse(skills.isEmpty)
        let withResources = skills.filter { !$0.resources.isEmpty }
        XCTAssertEqual(withResources.count, skills.count, "Every skill ships with at least one resource")
    }

    func testProjectsAreLinkedToRoles() {
        let projects = PersistenceService.fetchAll(Project.self, in: context)
        XCTAssertFalse(projects.isEmpty)
        for project in projects {
            XCTAssertFalse(project.roles.isEmpty, "\(project.slug) not linked to any role")
            XCTAssertFalse(project.milestones.isEmpty, "\(project.slug) has no milestones")
        }
    }

    func testSkillProgressUpsertIsStable() {
        let first = PersistenceService.skillProgress(forSkillSlug: "python", in: context)
        first.level = 4
        try? context.save()

        let second = PersistenceService.skillProgress(forSkillSlug: "python", in: context)
        XCTAssertEqual(second.level, 4, "Fetching progress twice must return the same record")

        let all = PersistenceService.fetchAll(SkillProgress.self, in: context)
            .filter { $0.skillSlug == "python" }
        XCTAssertEqual(all.count, 1, "skillSlug must be unique")
    }

    func testProfileIsCreatedOnce() {
        let first = PersistenceService.profile(in: context)
        first.dailyMinutes = 99
        try? context.save()
        let second = PersistenceService.profile(in: context)
        XCTAssertEqual(second.dailyMinutes, 99)
        XCTAssertEqual(PersistenceService.fetchAll(UserProfile.self, in: context).count, 1)
    }

    func testLearningSessionsMergePerDay() {
        PersistenceService.logLearningSession(minutes: 20, skillSlug: nil, in: context)
        PersistenceService.logLearningSession(minutes: 25, skillSlug: "python", in: context)
        try? context.save()

        let today = Calendar.current.startOfDay(for: .now)
        let sessions = PersistenceService.fetchAll(LearningSession.self, in: context)
            .filter { Calendar.current.isDate($0.day, inSameDayAs: today) }
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.minutes, 45)
    }

    func testResetProgressClearsUserStateOnly() {
        let progress = PersistenceService.skillProgress(forSkillSlug: "python", in: context)
        progress.level = 5
        progress.status = .completed
        PersistenceService.logLearningSession(minutes: 30, skillSlug: nil, in: context)
        let profile = PersistenceService.profile(in: context)
        profile.hasCompletedOnboarding = true
        try? context.save()

        SeedService.resetUserProgress(in: context)

        XCTAssertTrue(PersistenceService.fetchAll(SkillProgress.self, in: context).isEmpty)
        XCTAssertTrue(PersistenceService.fetchAll(LearningSession.self, in: context).isEmpty)
        XCTAssertEqual(PersistenceService.fetchAll(CareerRole.self, in: context).count, 14,
                       "Catalogue must survive a reset")
        let resetProfile = PersistenceService.profile(in: context)
        XCTAssertFalse(resetProfile.hasCompletedOnboarding)
    }
}
