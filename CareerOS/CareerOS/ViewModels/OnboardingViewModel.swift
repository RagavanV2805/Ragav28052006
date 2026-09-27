import Foundation
import SwiftData

/// Drives the multi-step onboarding: experience → known skills → DSA &
/// CS fundamentals → projects done → time budget → target role → timeline →
/// confidence → review.
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome
        case experience
        case knownSkills
        case dsaAndFundamentals
        case timeAndTimeline
        case roleSelection
        case review
    }

    // MARK: Assessment state

    var name: String = ""
    var experienceLevel: ExperienceLevel = .student
    var knownSkillSlugs: Set<String> = []
    var skillRatings: [String: Int] = [:]
    var dsaLevel: Int = 0
    var csFundamentalsLevel: Int = 0
    var completedProjectsCount: Int = 0
    var dailyMinutes: Int = 60
    var targetRoleSlug: String?
    var targetMonths: Int = 6
    var confidenceLevel: Int = 2

    // MARK: Navigation

    var step: Step = .welcome
    var validationMessage: String?

    var progressFraction: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    // MARK: Derived data

    /// Language skills offered in the "what do you know?" step.
    func languageChoices(from skills: [Skill]) -> [Skill] {
        skills.filter { $0.category == .language }
            .sorted { $0.name < $1.name }
    }

    /// Broad skills rated during assessment.
    func assessmentSkillChoices(from skills: [Skill]) -> [Skill] {
        let slugs: Set<String> = [
            "programming-fundamentals", "oop", "data-structures", "algorithms",
            "dbms", "sql", "git-version-control", "operating-systems",
            "computer-networks", "linux-basics", "html-css", "statistics",
        ]
        return skills.filter { slugs.contains($0.slug) }
    }

    // MARK: Validation & navigation

    func canAdvance() -> Bool {
        switch step {
        case .roleSelection:
            return targetRoleSlug != nil
        default:
            return true
        }
    }

    func advance() {
        validationMessage = nil
        if !canAdvance() {
            validationMessage = step == .roleSelection
                ? "Choose the role you want to work towards."
                : nil
            return
        }
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func goBack() {
        validationMessage = nil
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    // MARK: Finish

    /// Persists the assessment, seeds initial skill progress and hands the
    /// user over to the main app.
    func finish(context: ModelContext) async {
        let profile = PersistenceService.profile(in: context)
        profile.name = name
        profile.experienceLevel = experienceLevel
        profile.dsaLevel = dsaLevel
        profile.csFundamentalsLevel = csFundamentalsLevel
        profile.completedProjectsCount = completedProjectsCount
        profile.dailyMinutes = dailyMinutes
        profile.targetRoleSlug = targetRoleSlug
        profile.targetDate = Calendar.current.date(byAdding: .month, value: targetMonths, to: .now)
        profile.confidenceLevel = confidenceLevel
        profile.knownLanguages = knownLanguageNames(from: context)
        if profile.notificationPreference == nil {
            profile.notificationPreference = NotificationPreference()
        }

        applyAssessedSkillLevels(context: context)

        profile.hasCompletedOnboarding = true
        try? context.save()

        if !UITestMode.isActive, let preference = profile.notificationPreference {
            await NotificationService.shared.apply(preference)
        }

        WidgetSnapshotPublisher.publish(context: context)
    }

    /// Maps assessment ratings onto SkillProgress records so the roadmap
    /// starts from the right place instead of zero.
    private func applyAssessedSkillLevels(context: ModelContext) {
        var ratings = skillRatings
        // Seed implicit knowledge: languages marked as known get level >= 2.
        for slug in knownSkillSlugs where ratings[slug] == nil {
            ratings[slug] = SkillLevel.basic.rawValue
        }
        // Bridge DSA/CS questionnaires onto canonical skills.
        ratings["data-structures"] = max(ratings["data-structures"] ?? 0, min(dsaLevel, 5))
        ratings["algorithms"] = max(ratings["algorithms"] ?? 0, min(dsaLevel, 5))
        let csLevel = min(csFundamentalsLevel, 5)
        for slug in ["operating-systems", "computer-networks", "dbms"] {
            ratings[slug] = max(ratings[slug] ?? 0, csLevel)
        }

        for (slug, level) in ratings {
            let progress = PersistenceService.skillProgress(forSkillSlug: slug, in: context)
            progress.level = level
            if level >= SkillLevel.intermediate.rawValue && progress.status == .notStarted {
                progress.status = .completed
                progress.completedAt = .now
            } else if level > 0 && progress.status == .notStarted {
                progress.status = .inProgress
                progress.startedAt = .now
            }
        }
    }

    private func knownLanguageNames(from context: ModelContext) -> [String] {
        knownSkillSlugs
            .compactMap { PersistenceService.skill(slug: $0, in: context)?.name }
            .sorted()
    }
}
