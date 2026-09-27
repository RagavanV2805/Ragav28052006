import Foundation

/// A framework-agnostic snapshot of a roadmap node used by the planning
/// engine. Keeping this a value type makes the engine trivially testable.
struct PlannerSkill: Identifiable, Hashable {
    let id: String
    let name: String
    let stageIndex: Int
    /// 1...5 importance for the target role.
    let importance: Int
    let isOptional: Bool
    /// Target self-rating (0...5) for the role.
    let targetLevel: Int
    let estimatedHours: Double
    /// Required prerequisite skill ids.
    let requiredPrerequisiteIDs: [String]
    /// The user's current self-rating.
    let userLevel: Int
    /// Explicitly marked complete by the user.
    let isCompleted: Bool
    let isInProgress: Bool

    /// A node is "met" when completed or rated at/above the role's target.
    var isMet: Bool { isCompleted || userLevel >= targetLevel }
}

/// A scored suggestion with human-readable justification.
struct SkillRecommendation: Identifiable, Hashable {
    let skill: PlannerSkill
    let score: Double
    let reasons: [String]
    let estimatedDays: Int?
    let unlockedSkillNames: [String]
    /// True when this suggestion exists to unblock prerequisites.
    let isBlockerSuggestion: Bool

    var id: String { skill.id }
}

/// The result of planning "what should I learn next".
struct LearningPlan {
    let primary: SkillRecommendation?
    let alternates: [SkillRecommendation]
    /// Suggestions emitted when everything eligible is blocked.
    let blockerSuggestions: [SkillRecommendation]

    var isEmpty: Bool {
        primary == nil && blockerSuggestions.isEmpty
    }
}

/// Decides what the user should learn next.
///
/// Inputs: the target role's nodes (as `PlannerSkill`) plus the set of skill
/// ids the user has already satisfied *anywhere* (so a prerequisite met in a
/// previous role still counts). Output: a ranked plan with reasons.
struct RecommendationEngine {
    /// Minimum level for a skill outside the roadmap to count as satisfied.
    static let externalSatisfactionLevel = SkillLevel.intermediate.rawValue

    func plan(
        skills: [PlannerSkill],
        satisfiedExternalIDs: Set<String>,
        dailyMinutes: Int
    ) -> LearningPlan {
        let metIDs = satisfiedIDs(in: skills, external: satisfiedExternalIDs)
        let unlocksByID = unlockMap(for: skills)

        var eligible: [SkillRecommendation] = []
        var blocked: [PlannerSkill] = []

        for skill in skills where !skill.isMet {
            let missing = skill.requiredPrerequisiteIDs.filter { !metIDs.contains($0) }
            if missing.isEmpty {
                eligible.append(
                    makeRecommendation(
                        skill: skill,
                        skills: skills,
                        metIDs: metIDs,
                        unlocksByID: unlocksByID,
                        dailyMinutes: dailyMinutes,
                        isBlocker: false
                    )
                )
            } else {
                blocked.append(skill)
            }
        }

        let ranked = eligible.sorted { $0.score > $1.score }
        let primary = ranked.first
        let alternates = Array(ranked.dropFirst().prefix(3))

        var blockers: [SkillRecommendation] = []
        if primary == nil {
            blockers = blockerSuggestions(
                blocked: blocked,
                skills: skills,
                metIDs: metIDs,
                unlocksByID: unlocksByID,
                dailyMinutes: dailyMinutes
            )
        }

        return LearningPlan(primary: primary, alternates: alternates, blockerSuggestions: blockers)
    }

    /// IDs of skills the user has satisfied — inside the roadmap or globally.
    func satisfiedIDs(in skills: [PlannerSkill], external: Set<String>) -> Set<String> {
        var result = external
        for skill in skills where skill.isMet {
            result.insert(skill.id)
        }
        return result
    }

    /// skill id -> names of roadmap skills it unlocks (that are not yet met).
    private func unlockMap(for skills: [PlannerSkill]) -> [String: [String]] {
        var map: [String: [String]] = [:]
        for skill in skills where !skill.isMet {
            for prereq in skill.requiredPrerequisiteIDs {
                map[prereq, default: []].append(skill.name)
            }
        }
        return map
    }

    private func makeRecommendation(
        skill: PlannerSkill,
        skills: [PlannerSkill],
        metIDs: Set<String>,
        unlocksByID: [String: [String]],
        dailyMinutes: Int,
        isBlocker: Bool
    ) -> SkillRecommendation {
        let unlocks = (unlocksByID[skill.id] ?? []).sorted()

        var score = Double(skill.importance) * 20.0
        score += Double(unlocks.count) * 8.0
        score += Double(max(0, 6 - skill.stageIndex)) * 2.0
        if !skill.isOptional {
            score += 10.0
        } else {
            score -= 12.0
        }
        if skill.isInProgress {
            // Momentum: finishing what you started beats starting something new.
            score += 15.0
        }
        if let days = estimatedDays(for: skill, dailyMinutes: dailyMinutes), days > 21 {
            score -= 4.0
        }

        var reasons: [String] = []
        if skill.isInProgress {
            reasons.append("You're already working on it — finish strong")
        }
        reasons.append(
            skill.isOptional
                ? "A valuable optional skill for your target role"
                : "Required for your target role (importance \(skill.importance)/5)"
        )
        if skill.requiredPrerequisiteIDs.isEmpty {
            reasons.append("No prerequisites — you can start right away")
        } else {
            let metPrereqNames = skill.requiredPrerequisiteIDs
                .filter { metIDs.contains($0) }
                .compactMap { id in skills.first { $0.id == id }?.name }
            if metPrereqNames.isEmpty {
                reasons.append("All prerequisites are satisfied by your existing skills")
            } else {
                reasons.append("Your prerequisites are complete: \(metPrereqNames.joined(separator: ", "))")
            }
        }
        if !unlocks.isEmpty {
            reasons.append("Unlocks: \(unlocks.joined(separator: ", "))")
        }
        if let days = estimatedDays(for: skill, dailyMinutes: dailyMinutes) {
            reasons.append("About \(Int(skill.estimatedHours))h of effort — roughly \(days) day\(days == 1 ? "" : "s") at your pace")
        }

        return SkillRecommendation(
            skill: skill,
            score: score,
            reasons: reasons,
            estimatedDays: estimatedDays(for: skill, dailyMinutes: dailyMinutes),
            unlockedSkillNames: unlocks,
            isBlockerSuggestion: isBlocker
        )
    }

    /// When everything is blocked, find the highest-leverage missing
    /// prerequisites and recommend those instead.
    private func blockerSuggestions(
        blocked: [PlannerSkill],
        skills: [PlannerSkill],
        metIDs: Set<String>,
        unlocksByID: [String: [String]],
        dailyMinutes: Int
    ) -> [SkillRecommendation] {
        let blockedByPriority = blocked.sorted { $0.importance > $1.importance }
        var seen = Set<String>()
        var results: [SkillRecommendation] = []

        for skill in blockedByPriority {
            let missing = skill.requiredPrerequisiteIDs.filter { !metIDs.contains($0) }
            // Prefer prerequisites that themselves have no unmet prerequisites.
            let ready = missing.filter { id in
                guard let candidate = skills.first(where: { $0.id == id }) else { return true }
                return candidate.requiredPrerequisiteIDs.allSatisfy { metIDs.contains($0) }
            }
            let picks = ready.isEmpty ? missing : ready
            for id in picks where !seen.contains(id) {
                seen.insert(id)
                if let candidate = skills.first(where: { $0.id == id }), !candidate.isMet {
                    var rec = makeRecommendation(
                        skill: candidate,
                        skills: skills,
                        metIDs: metIDs,
                        unlocksByID: unlocksByID,
                        dailyMinutes: dailyMinutes,
                        isBlocker: true
                    )
                    rec = SkillRecommendation(
                        skill: rec.skill,
                        score: rec.score,
                        reasons: ["Unblocks \(skill.name), which your roadmap needs"] + rec.reasons,
                        estimatedDays: rec.estimatedDays,
                        unlockedSkillNames: rec.unlockedSkillNames,
                        isBlockerSuggestion: true
                    )
                    results.append(rec)
                }
            }
            if results.count >= 3 { break }
        }
        return results
    }

    func estimatedDays(for skill: PlannerSkill, dailyMinutes: Int) -> Int? {
        guard dailyMinutes > 0 else { return nil }
        let minutes = skill.estimatedHours * 60
        let remaining = max(0, skill.targetLevel - skill.userLevel)
        let fraction = skill.targetLevel > 0 ? Double(remaining) / Double(skill.targetLevel) : 1
        return max(1, Int((minutes * fraction / Double(dailyMinutes)).rounded(.up)))
    }
}
