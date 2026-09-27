import XCTest
@testable import CareerOS

final class StreakCalculatorTests: XCTestCase {
    private let calculator = StreakCalculator()
    private var calendar: Calendar { .current }

    private func day(_ offset: Int, from reference: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: reference))!
    }

    func testNoActivityZeroStreak() {
        let today = Date.now
        let result = calculator.streak(activeDays: [], today: today)
        XCTAssertEqual(result.length, 0)
        XCTAssertFalse(result.atRisk)
    }

    func testSingleDayToday() {
        let today = Date.now
        let result = calculator.streak(activeDays: [today], today: today)
        XCTAssertEqual(result.length, 1)
        XCTAssertFalse(result.atRisk)
    }

    func testConsecutiveDays() {
        let today = Date.now
        let days = [day(-2, from: today), day(-1, from: today), day(0, from: today)]
        let result = calculator.streak(activeDays: Set(days), today: today)
        XCTAssertEqual(result.length, 3)
        XCTAssertFalse(result.atRisk)
    }

    func testStreakSurvivesUntilTomorrowWhenActiveYesterdayOnly() {
        let today = Date.now
        let days = [day(-2, from: today), day(-1, from: today)]
        let result = calculator.streak(activeDays: Set(days), today: today)
        XCTAssertEqual(result.length, 2)
        XCTAssertTrue(result.atRisk)
    }

    func testGapBreaksStreak() {
        let today = Date.now
        // Active today and two days ago, but not yesterday → streak of 1.
        let days = [day(-2, from: today), day(0, from: today)]
        let result = calculator.streak(activeDays: Set(days), today: today)
        XCTAssertEqual(result.length, 1)
    }

    func testInactiveForTwoDaysResetsStreak() {
        let today = Date.now
        let days = [day(-3, from: today), day(-2, from: today)]
        let result = calculator.streak(activeDays: Set(days), today: today)
        XCTAssertEqual(result.length, 0)
    }
}
