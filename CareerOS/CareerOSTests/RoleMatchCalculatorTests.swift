import XCTest
@testable import CareerOS

final class RoleMatchCalculatorTests: XCTestCase {
    private let calculator = RoleMatchCalculator()

    private func role(nodes: [RoleRequirementSnapshot.Node]) -> RoleRequirementSnapshot {
        RoleRequirementSnapshot(roleSlug: "test", roleName: "Test Role", iconName: "target", nodes: nodes)
    }

    private func node(_ id: String, importance: Int = 5, target: Int = 3, optional: Bool = false) -> RoleRequirementSnapshot.Node {
        RoleRequirementSnapshot.Node(skillID: id, skillName: id.capitalized, importance: importance, targetLevel: target, isOptional: optional)
    }

    func testZeroSkillsZeroPercent() {
        let match = calculator.match(
            for: role(nodes: [node("a"), node("b")]),
            levels: [:], completedIDs: [], inProgressIDs: []
        )
        XCTAssertEqual(match.matchPercent, 0)
    }

    func testFullyCoveredRoleIs100Percent() {
        let match = calculator.match(
            for: role(nodes: [node("a"), node("b")]),
            levels: [:], completedIDs: ["a", "b"], inProgressIDs: []
        )
        XCTAssertEqual(match.matchPercent, 100)
        XCTAssertEqual(match.matchedSkillNames.sorted(), ["A", "B"])
    }

    func testPartialLevelGivesPartialCredit() {
        // One skill at level 1 of target 3 → 1/3 credit weighted equally.
        let match = calculator.match(
            for: role(nodes: [node("a", target: 3), node("b", target: 3)]),
            levels: ["a": 1], completedIDs: [], inProgressIDs: []
        )
        // earned = 5 * 1/3, total = 10 → ~17%
        XCTAssertEqual(Double(match.matchPercent), 17, accuracy: 1)
    }

    func testImportanceWeightsApply() {
        // High importance skill done, low importance missing.
        let match = calculator.match(
            for: role(nodes: [node("a", importance: 5), node("b", importance: 1)]),
            levels: [:], completedIDs: ["a"], inProgressIDs: []
        )
        // 5/6 → 83%
        XCTAssertEqual(Double(match.matchPercent), 83, accuracy: 1)
    }

    func testOptionalSkillsDoNotAffectPercentButAreListed() {
        let match = calculator.match(
            for: role(nodes: [node("a"), node("opt", optional: true)]),
            levels: [:], completedIDs: ["a", "opt"], inProgressIDs: []
        )
        XCTAssertEqual(match.matchPercent, 100)
        XCTAssertEqual(match.optionalSkillNames, ["Opt"])
    }

    func testMissingAndInProgressBuckets() {
        let match = calculator.match(
            for: role(nodes: [node("a"), node("b"), node("c")]),
            levels: ["b": 1],
            completedIDs: ["a"],
            inProgressIDs: ["b"]
        )
        XCTAssertEqual(match.matchedSkillNames, ["A"])
        XCTAssertEqual(match.inProgressSkillNames, ["B"])
        XCTAssertEqual(match.missingSkillNames, ["C"])
    }

    func testMatchesSortedByPercentDescending() {
        let matches = calculator.matches(
            for: [
                role(nodes: [node("a")]),
                RoleRequirementSnapshot(roleSlug: "other", roleName: "Other", iconName: "x", nodes: [node("a"), node("z")]),
            ],
            levels: [:], completedIDs: ["a"], inProgressIDs: []
        )
        XCTAssertEqual(matches.first?.roleSlug, "test")
    }
}
