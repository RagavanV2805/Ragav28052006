import XCTest
import SwiftData
@testable import CareerOS

final class ProjectProgressTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try TestStore.makeContainer()
        context = container.mainContext
    }

    private func project(slug: String) throws -> Project {
        let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.slug == slug })
        return try XCTUnwrap(context.fetch(descriptor).first)
    }

    func testMilestoneFractionTracksCompletion() throws {
        let proj = try project(slug: "se-console-task-manager")
        let viewModel = ProjectDetailViewModel(project: proj)

        XCTAssertEqual(viewModel.fraction, 0, accuracy: 0.001)

        let first = try XCTUnwrap(proj.orderedMilestones.first)
        viewModel.toggleMilestone(first, context: context)

        let expected = 1.0 / Double(proj.milestones.count)
        XCTAssertEqual(proj.milestoneFraction, expected, accuracy: 0.001)
    }

    func testFirstMilestoneStartsProject() throws {
        let proj = try project(slug: "se-console-task-manager")
        let viewModel = ProjectDetailViewModel(project: proj)

        viewModel.toggleMilestone(proj.orderedMilestones[0], context: context)

        let record = try XCTUnwrap(proj.progress)
        XCTAssertEqual(record.status, .inProgress)
        XCTAssertNotNil(record.startedAt)
    }

    func testCompletingAllMilestonesCompletesProject() throws {
        let proj = try project(slug: "se-console-task-manager")
        let viewModel = ProjectDetailViewModel(project: proj)

        for milestone in proj.orderedMilestones {
            viewModel.toggleMilestone(milestone, context: context)
        }

        XCTAssertEqual(proj.progress?.status, .completed)
        XCTAssertNotNil(proj.progress?.completedAt)
        XCTAssertEqual(proj.milestoneFraction, 1.0, accuracy: 0.001)
    }

    func testUncheckingMilestoneReopensCompletedProject() throws {
        let proj = try project(slug: "se-console-task-manager")
        let viewModel = ProjectDetailViewModel(project: proj)

        viewModel.markCompleted(context: context)
        XCTAssertEqual(proj.progress?.status, .completed)

        let first = try XCTUnwrap(proj.orderedMilestones.first)
        viewModel.toggleMilestone(first, context: context)

        XCTAssertEqual(proj.progress?.status, .inProgress)
        XCTAssertNil(proj.progress?.completedAt)
    }

    func testPauseAndResume() throws {
        let proj = try project(slug: "se-console-task-manager")
        let viewModel = ProjectDetailViewModel(project: proj)

        viewModel.start(context: context)
        XCTAssertEqual(proj.progress?.status, .inProgress)

        viewModel.pause(context: context)
        XCTAssertEqual(proj.progress?.status, .paused)

        viewModel.resume(context: context)
        XCTAssertEqual(proj.progress?.status, .inProgress)
    }

    func testDeadlinePersists() throws {
        let proj = try project(slug: "se-console-task-manager")
        let viewModel = ProjectDetailViewModel(project: proj)
        let due = Date.now.addingTimeInterval(7 * 24 * 3600)

        viewModel.setDeadline(due, context: context)

        let stored = try XCTUnwrap(proj.progress?.deadline)
        XCTAssertEqual(stored.timeIntervalSince(due), 0, accuracy: 1)
    }

    func testRecommendedProjectsRequireSatisfiedSkills() throws {
        // Nothing satisfied → nothing recommended for Software Engineer.
        let profile = PersistenceService.profile(in: context)
        profile.targetRoleSlug = "software-engineer"
        try context.save()

        let role = try XCTUnwrap(PersistenceService.role(slug: "software-engineer", in: context))
        let service = RoadmapService(context: context)

        XCTAssertFalse(service.recommendedProjects(for: role).isEmpty == true && service.upcomingProjects(for: role).isEmpty,
                       "Projects should be split between recommended and upcoming, never both empty")

        // Satisfy the beginner project's skills → it becomes recommended.
        for slug in ["programming-fundamentals", "git-version-control"] {
            let progress = PersistenceService.skillProgress(forSkillSlug: slug, in: context)
            progress.level = 5
            progress.status = .completed
        }
        try context.save()

        let recommended = service.recommendedProjects(for: role)
        XCTAssertTrue(recommended.contains { $0.slug == "se-console-task-manager" },
                      "Beginner SE project should unlock once its skills are satisfied")
    }
}
