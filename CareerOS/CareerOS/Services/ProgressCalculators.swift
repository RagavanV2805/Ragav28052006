import Foundation

// MARK: - Roadmap progress

struct StageProgress: Identifiable, Hashable {
    let stage: RoadmapStage
    let fraction: Double
    let completedCount: Int
    let totalCount: Int

    var id: Int { stage.rawValue }
}

struct RoadmapProgressSummary: Hashable {
    /// Weighted completion of required nodes, 0...1.
    let overallFraction: Double
    let requiredTotal: Int
    let requiredCompleted: Int
    let optionalCompleted: Int
    let optionalTotal: Int
    let byStage: [StageProgress]

    var overallPercent: Int { Int((overallFraction * 100).rounded()) }
}

/// Pure computation of roadmap completion from node states.
struct RoadmapProgressCalculator {
    struct NodeState {
        let stageIndex: Int
        let importance: Int
        let isOptional: Bool
        let isMet: Bool
    }

    func summary(for nodes: [NodeState]) -> RoadmapProgressSummary {
        var earned = 0.0
        var total = 0.0
        var requiredCompleted = 0
        var requiredTotal = 0
        var optionalCompleted = 0
        var optionalTotal = 0
        var stageBuckets: [Int: (earned: Double, total: Double, done: Int, count: Int)] = [:]

        for node in nodes {
            if node.isOptional {
                optionalTotal += 1
                if node.isMet { optionalCompleted += 1 }
                continue
            }

            let weight = Double(node.importance)
            total += weight
            requiredTotal += 1
            if node.isMet {
                earned += weight
                requiredCompleted += 1
            }

            var bucket = stageBuckets[node.stageIndex] ?? (0, 0, 0, 0)
            bucket.total += weight
            if node.isMet { bucket.earned += weight; bucket.done += 1 }
            bucket.count += 1
            stageBuckets[node.stageIndex] = bucket
        }

        let byStage: [StageProgress] = RoadmapStage.allCases.compactMap { stage in
            guard let bucket = stageBuckets[stage.rawValue], bucket.count > 0 else { return nil }
            return StageProgress(
                stage: stage,
                fraction: bucket.total > 0 ? bucket.earned / bucket.total : 0,
                completedCount: bucket.done,
                totalCount: bucket.count
            )
        }

        return RoadmapProgressSummary(
            overallFraction: total > 0 ? earned / total : 0,
            requiredTotal: requiredTotal,
            requiredCompleted: requiredCompleted,
            optionalCompleted: optionalCompleted,
            optionalTotal: optionalTotal,
            byStage: byStage
        )
    }
}

// MARK: - Streaks

/// Consecutive-day streak over a set of active days.
struct StreakCalculator {
    /// Returns the current streak length in days. A streak survives until the
    /// end of "today"; if the user was active yesterday but not yet today the
    /// streak is still reported (with `atRisk` set).
    func streak(
        activeDays: Set<Date>,
        today: Date = Calendar.current.startOfDay(for: .now),
        calendar: Calendar = .current
    ) -> (length: Int, atRisk: Bool) {
        let normalized = Set(activeDays.map { calendar.startOfDay(for: $0) })
        let todayStart = calendar.startOfDay(for: today)

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return (0, false)
        }

        var cursor: Date
        var atRisk = false
        if normalized.contains(todayStart) {
            cursor = todayStart
        } else if normalized.contains(yesterday) {
            cursor = yesterday
            atRisk = true
        } else {
            return (0, false)
        }

        var length = 0
        while normalized.contains(cursor) {
            length += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return (length, atRisk)
    }
}

// MARK: - Project recommendation eligibility

/// Determines whether a project's prerequisites are satisfied so it can be
/// recommended. Pure logic; UI-free.
struct ProjectEligibilityCalculator {
    func isEligible(requiredSkillIDs: [String], satisfiedIDs: Set<String>) -> Bool {
        requiredSkillIDs.allSatisfy { satisfiedIDs.contains($0) }
    }

    /// 0...1 fraction of required skills satisfied — used to sort near-ready
    /// projects above far-away ones.
    func readiness(requiredSkillIDs: [String], satisfiedIDs: Set<String>) -> Double {
        guard !requiredSkillIDs.isEmpty else { return 1 }
        let met = requiredSkillIDs.filter { satisfiedIDs.contains($0) }.count
        return Double(met) / Double(requiredSkillIDs.count)
    }
}
