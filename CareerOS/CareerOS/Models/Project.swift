import Foundation
import SwiftData

/// A portfolio project attached to one or more career roles.
@Model
final class Project {
    @Attribute(.unique) var slug: String
    var title: String
    var summary: String
    var difficultyRaw: String
    var estimatedWeeks: Int
    var technologyStack: [String]
    var learningOutcomes: [String]

    @Relationship(deleteRule: .cascade, inverse: \ProjectMilestone.project)
    var milestones: [ProjectMilestone] = []

    /// Skills the user should have before starting (many-to-many).
    var requiredSkills: [Skill] = []
    /// Skills that make the project easier or extend it.
    var optionalSkills: [Skill] = []

    var roles: [CareerRole] = []

    @Relationship(deleteRule: .cascade, inverse: \ProjectProgress.project)
    var progress: ProjectProgress?

    init(
        slug: String,
        title: String,
        summary: String,
        difficulty: ProjectDifficulty,
        estimatedWeeks: Int,
        technologyStack: [String],
        learningOutcomes: [String]
    ) {
        self.slug = slug
        self.title = title
        self.summary = summary
        self.difficultyRaw = difficulty.rawValue
        self.estimatedWeeks = estimatedWeeks
        self.technologyStack = technologyStack
        self.learningOutcomes = learningOutcomes
    }

    var difficulty: ProjectDifficulty {
        get { ProjectDifficulty(rawValue: difficultyRaw) ?? .beginner }
        set { difficultyRaw = newValue.rawValue }
    }

    var orderedMilestones: [ProjectMilestone] {
        milestones.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Milestone-derived completion in 0...1. A project with no milestones is
    /// either fully done or untouched.
    var milestoneFraction: Double {
        let all = milestones
        guard !all.isEmpty else {
            return progress?.status == .completed ? 1 : 0
        }
        let done = all.filter(\.isDone).count
        return Double(done) / Double(all.count)
    }
}

@Model
final class ProjectMilestone {
    var title: String
    var orderIndex: Int
    var isDone: Bool
    var completedAt: Date?
    var project: Project?

    init(title: String, orderIndex: Int, isDone: Bool = false) {
        self.title = title
        self.orderIndex = orderIndex
        self.isDone = isDone
    }
}
