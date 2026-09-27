import XCTest
@testable import CareerOS

final class RecommendationEngineTests: XCTestCase {
    private let engine = RecommendationEngine()

    private func skill(
        _ id: String,
        importance: Int = 5,
        optional: Bool = false,
        target: Int = 3,
        hours: Double = 20,
        prereqs: [String] = [],
        level: Int = 0,
        completed: Bool = false,
        inProgress: Bool = false,
        stage: Int = 1
    ) -> PlannerSkill {
        PlannerSkill(
            id: id,
            name: id.capitalized,
            stageIndex: stage,
            importance: importance,
            isOptional: optional,
            targetLevel: target,
            estimatedHours: hours,
            requiredPrerequisiteIDs: prereqs,
            userLevel: level,
            isCompleted: completed,
            isInProgress: inProgress
        )
    }

    func testRecommendsHighestImportanceEligibleSkill() {
        let plan = engine.plan(
            skills: [
                skill("python", importance: 5),
                skill("sql", importance: 3),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "python")
    }

    func testPrerequisiteBlocksRecommendation() {
        // Algorithms requires Data Structures; only Algorithms is high importance.
        let plan = engine.plan(
            skills: [
                skill("data-structures", importance: 3),
                skill("algorithms", importance: 5, prereqs: ["data-structures"]),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "data-structures",
                       "A skill must not be recommended before its prerequisites are met.")
    }

    func testSatisfiedPrerequisiteUnlocksDependent() {
        let plan = engine.plan(
            skills: [
                skill("data-structures", importance: 3, level: 4, completed: true),
                skill("algorithms", importance: 5, prereqs: ["data-structures"]),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "algorithms")
    }

    func testExternalSatisfactionCounts() {
        // Python learned in another context still satisfies the prerequisite.
        let plan = engine.plan(
            skills: [
                skill("pandas", importance: 5, prereqs: ["python"]),
            ],
            satisfiedExternalIDs: ["python"],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "pandas")
        XCTAssertTrue(plan.primary?.reasons.contains { $0.contains("prerequisites") } ?? false)
    }

    func testCompletedSkillsAreNeverRecommended() {
        let plan = engine.plan(
            skills: [
                skill("git", importance: 5, completed: true),
                skill("sql", importance: 2),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "sql")
    }

    func testLevelAtTargetCountsAsMet() {
        let plan = engine.plan(
            skills: [
                skill("python", importance: 5, target: 3, level: 3),
                skill("sql", importance: 2),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "sql", "Rated at target level counts as met.")
    }

    func testInProgressSkillGetsMomentumBoost() {
        let plan = engine.plan(
            skills: [
                skill("sql", importance: 5),
                skill("git", importance: 5, inProgress: true),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(plan.primary?.skill.id, "git")
    }

    func testEstimatesDaysFromDailyBudget() {
        let rec = engine.plan(
            skills: [skill("python", hours: 10)],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        ).primary
        // 10h @ target 3 from level 0 → 10h * 60 / 60min = 10 days.
        XCTAssertEqual(rec?.estimatedDays, 10)
    }

    func testHigherDailyBudgetReducesEstimate() {
        let rec = engine.plan(
            skills: [skill("python", hours: 10)],
            satisfiedExternalIDs: [],
            dailyMinutes: 120
        ).primary
        XCTAssertEqual(rec?.estimatedDays, 5)
    }

    func testUnlocksAreReported() {
        let plan = engine.plan(
            skills: [
                skill("python", importance: 4),
                skill("pandas", importance: 4, prereqs: ["python"]),
                skill("ml", importance: 4, prereqs: ["python"]),
            ],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertEqual(Set(plan.primary?.unlockedSkillNames ?? []), ["Pandas", "Ml"])
    }

    func testBlockerFallbackWhenEverythingLocked() {
        // x depends on a skill *outside* the roadmap that the user hasn't
        // learned; y depends on x. Nothing is eligible, so the engine must
        // fall back to blocker guidance recommending x (which unblocks y).
        let skills = [
            skill("x", importance: 3, prereqs: ["external-missing"]),
            skill("y", importance: 5, prereqs: ["x"]),
        ]
        let plan = engine.plan(skills: skills, satisfiedExternalIDs: [], dailyMinutes: 60)
        XCTAssertNil(plan.primary)
        XCTAssertFalse(plan.blockerSuggestions.isEmpty, "Engine should surface blocker guidance when nothing is eligible.")
        XCTAssertEqual(plan.blockerSuggestions.first?.skill.id, "x")
        XCTAssertTrue(plan.blockerSuggestions.first?.isBlockerSuggestion ?? false)
    }

    func testReasonsMentionRoleRequirement() {
        let plan = engine.plan(
            skills: [skill("python", importance: 5)],
            satisfiedExternalIDs: [],
            dailyMinutes: 60
        )
        XCTAssertTrue(plan.primary?.reasons.contains { $0.contains("Required for your target role") } ?? false)
    }
}
