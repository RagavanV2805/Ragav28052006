import XCTest

/// Critical journey: Onboarding → Role selection → Skill assessment →
/// Roadmap → Skill completion → Dashboard update.
final class OnboardingJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
    }

    func testOnboardingToSkillCompletionUpdatesDashboard() throws {
        // 1. Welcome → start onboarding.
        let startButton = app.buttons["onboarding.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Welcome screen should appear on first launch")
        startButton.tap()

        // 2. Experience step → continue.
        continueOnboarding()

        // 3. Known skills step → continue (leave defaults: nothing known).
        continueOnboarding()

        // 4. DSA & fundamentals step → continue.
        continueOnboarding()

        // 5. Time & timeline step → continue.
        continueOnboarding()

        // 6. Role selection: pick Software Engineer.
        let roleButton = app.buttons["role.software-engineer"]
        XCTAssertTrue(roleButton.waitForExistence(timeout: 5), "Role grid should be visible")
        roleButton.tap()
        continueOnboarding()

        // 7. Review → finish onboarding.
        let finish = app.buttons["onboarding.continue"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()

        // 8. Dashboard appears with the target role.
        let dashboard = app.descendants(matching: .any)["dashboard.content"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 10), "Dashboard should be visible after onboarding")
        XCTAssertTrue(app.staticTexts["0 of 15 skills complete"].waitForExistence(timeout: 5),
                      "Fresh roadmap should report zero completed skills")

        // 9. Go to Roadmap tab and open Git & Version Control.
        app.tabBars.buttons["Roadmap"].tap()
        let gitSkill = app.staticTexts["Git & Version Control"].firstMatch
        XCTAssertTrue(gitSkill.waitForExistence(timeout: 5), "Fundamentals stage should be expanded by default")
        gitSkill.tap()

        // 10. Complete the skill.
        let completeButton = app.buttons["skill.complete"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        completeButton.tap()

        let completedLabel = app.otherElements["skill.completedLabel"]
        XCTAssertTrue(completedLabel.waitForExistence(timeout: 5), "Skill should show as completed")

        // 11. Back to dashboard → completion is reflected.
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Home"].tap()

        XCTAssertTrue(app.staticTexts["1 of 15 skills complete"].waitForExistence(timeout: 10),
                      "Dashboard must reflect the completed skill")
    }

    func testDashboardShowsRecommendationAfterOnboarding() throws {
        fastForwardOnboarding(selecting: "ios-developer")

        // The dashboard should offer a concrete next step.
        let startRecommended = app.buttons["dashboard.startRecommended"]
        XCTAssertTrue(startRecommended.waitForExistence(timeout: 10),
                      "Dashboard should surface a recommended next skill")
    }

    // MARK: - Helpers

    private func continueOnboarding() {
        let button = app.buttons["onboarding.continue"]
        guard button.waitForExistence(timeout: 5) else {
            XCTFail("Continue button missing")
            return
        }
        button.tap()
    }

    private func fastForwardOnboarding(selecting roleSlug: String) {
        app.buttons["onboarding.start"].tap()
        continueOnboarding() // experience
        continueOnboarding() // skills
        continueOnboarding() // fundamentals
        continueOnboarding() // time
        app.buttons["role.\(roleSlug)"].tap()
        continueOnboarding() // role
        continueOnboarding() // review → finish
    }
}
