import XCTest
@testable import CareerOS

final class RoadmapProgressTests: XCTestCase {
    private let calculator = RoadmapProgressCalculator()

    private func node(stage: Int = 0, importance: Int = 5, optional: Bool = false, met: Bool = false) -> RoadmapProgressCalculator.NodeState {
        RoadmapProgressCalculator.NodeState(stageIndex: stage, importance: importance, isOptional: optional, isMet: met)
    }

    func testEmptyRoadmapIsZero() {
        let summary = calculator.summary(for: [])
        XCTAssertEqual(summary.overallFraction, 0)
        XCTAssertEqual(summary.requiredTotal, 0)
    }

    func testWeightedByImportance() {
        // Two nodes: importance 5 met, importance 1 not met → 5/6.
        let summary = calculator.summary(for: [
            node(importance: 5, met: true),
            node(importance: 1, met: false),
        ])
        XCTAssertEqual(summary.overallFraction, 5.0 / 6.0, accuracy: 0.001)
        XCTAssertEqual(summary.overallPercent, 83)
    }

    func testOptionalNodesExcludedFromOverall() {
        let summary = calculator.summary(for: [
            node(met: true),
            node(optional: true, met: false),
        ])
        XCTAssertEqual(summary.overallFraction, 1.0)
        XCTAssertEqual(summary.optionalTotal, 1)
        XCTAssertEqual(summary.optionalCompleted, 0)
    }

    func testStageBreakdown() {
        let summary = calculator.summary(for: [
            node(stage: RoadmapStage.fundamentals.rawValue, met: true),
            node(stage: RoadmapStage.fundamentals.rawValue, met: false),
            node(stage: RoadmapStage.coreSkills.rawValue, met: true),
        ])
        XCTAssertEqual(summary.byStage.count, 2)
        let fundamentals = summary.byStage.first { $0.stage == .fundamentals }
        XCTAssertEqual(fundamentals?.completedCount, 1)
        XCTAssertEqual(fundamentals?.totalCount, 2)
        XCTAssertEqual(fundamentals?.fraction ?? 0, 0.5, accuracy: 0.001)
    }

    func testCompletedCounts() {
        let summary = calculator.summary(for: [
            node(met: true),
            node(met: true),
            node(met: false),
        ])
        XCTAssertEqual(summary.requiredCompleted, 2)
        XCTAssertEqual(summary.requiredTotal, 3)
    }
}
