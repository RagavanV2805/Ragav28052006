import Foundation

/// Snapshot of a role's requirements used for matching.
struct RoleRequirementSnapshot {
    struct Node {
        let skillID: String
        let skillName: String
        let importance: Int
        let targetLevel: Int
        let isOptional: Bool
    }

    let roleSlug: String
    let roleName: String
    let iconName: String
    let nodes: [Node]
}

/// Transparent, weighted match between the user's current skills and a role.
/// This is *not* a judgement of ability — it is simply how much of the role's
/// defined skill set the user already covers.
struct RoleMatch: Identifiable, Hashable {
    let roleSlug: String
    let roleName: String
    let iconName: String
    /// 0...100 weighted coverage of required skills.
    let matchPercent: Int
    let matchedSkillNames: [String]
    let inProgressSkillNames: [String]
    let missingSkillNames: [String]
    let optionalSkillNames: [String]

    var id: String { roleSlug }
}

struct RoleMatchCalculator {
    /// - Parameters:
    ///   - roles: all roles with their required/optional nodes.
    ///   - levels: current self-ratings keyed by skill id.
    ///   - completedIDs: skills explicitly marked complete.
    ///   - inProgressIDs: skills currently in progress.
    func matches(
        for roles: [RoleRequirementSnapshot],
        levels: [String: Int],
        completedIDs: Set<String>,
        inProgressIDs: Set<String>
    ) -> [RoleMatch] {
        roles.map { match(for: $0, levels: levels, completedIDs: completedIDs, inProgressIDs: inProgressIDs) }
            .sorted { $0.matchPercent > $1.matchPercent }
    }

    func match(
        for role: RoleRequirementSnapshot,
        levels: [String: Int],
        completedIDs: Set<String>,
        inProgressIDs: Set<String>
    ) -> RoleMatch {
        var earned = 0.0
        var total = 0.0
        var matched: [String] = []
        var inProgress: [String] = []
        var missing: [String] = []
        var optionals: [String] = []

        for node in role.nodes {
            if node.isOptional {
                if completedIDs.contains(node.skillID) || (levels[node.skillID] ?? 0) >= node.targetLevel {
                    optionals.append(node.skillName)
                }
                continue
            }

            let weight = Double(node.importance)
            total += weight

            let level = levels[node.skillID] ?? 0
            if completedIDs.contains(node.skillID) || level >= node.targetLevel {
                earned += weight
                matched.append(node.skillName)
            } else if level > 0 {
                earned += weight * min(1, Double(level) / Double(max(node.targetLevel, 1)))
                if inProgressIDs.contains(node.skillID) {
                    inProgress.append(node.skillName)
                } else {
                    missing.append(node.skillName)
                }
            } else {
                if inProgressIDs.contains(node.skillID) {
                    inProgress.append(node.skillName)
                } else {
                    missing.append(node.skillName)
                }
            }
        }

        let percent = total > 0 ? Int((earned / total * 100).rounded()) : 0
        return RoleMatch(
            roleSlug: role.roleSlug,
            roleName: role.roleName,
            iconName: role.iconName,
            matchPercent: min(100, max(0, percent)),
            matchedSkillNames: matched.sorted(),
            inProgressSkillNames: inProgress.sorted(),
            missingSkillNames: missing.sorted(),
            optionalSkillNames: optionals.sorted()
        )
    }
}
