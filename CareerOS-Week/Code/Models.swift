import SwiftUI
import SwiftData

// MARK: - Simple SwiftData models (one week version of CareerOS)

@Model
final class Skill {
    var name: String
    var stage: String          // "Basics", "Core", "Advanced"
    var hours: Int
    var isDone: Bool = false
    var prerequisiteNames: [String] = []

    init(name: String, stage: String, hours: Int, prereqs: [String] = []) {
        self.name = name
        self.stage = stage
        self.hours = hours
        self.prerequisiteNames = prereqs
    }

    func prerequisites(in role: Role) -> [Skill] {
        role.skills.filter { prerequisiteNames.contains($0.name) }
    }

    /// A skill is unlocked when all its prerequisites are done.
    func isUnlocked(in role: Role) -> Bool {
        prerequisites(in: role).allSatisfy(\.isDone)
    }
}

@Model
final class Project {
    var title: String
    var difficulty: String     // "Beginner", "Intermediate", "Advanced"
    var isDone: Bool = false
    var requiredSkillNames: [String] = []

    init(title: String, difficulty: String, required: [String]) {
        self.title = title
        self.difficulty = difficulty
        self.requiredSkillNames = required
    }

    func isReady(in role: Role) -> Bool {
        role.skills
            .filter { requiredSkillNames.contains($0.name) }
            .allSatisfy(\.isDone)
    }
}

@Model
final class Role {
    var name: String
    var icon: String
    @Relationship(deleteRule: .cascade) var skills: [Skill] = []
    @Relationship(deleteRule: .cascade) var projects: [Project] = []

    init(name: String, icon: String) {
        self.name = name
        self.icon = icon
    }

    var doneCount: Int { skills.filter(\.isDone).count }

    var progress: Double {
        skills.isEmpty ? 0 : Double(doneCount) / Double(skills.count)
    }

    /// First skill the user should learn next (unlocked & not done).
    var nextSkill: Skill? {
        skills.first { !$0.isDone && $0.isUnlocked(in: self) }
    }

    /// First project whose required skills are all done and not finished.
    var nextProject: Project? {
        projects.first { !$0.isDone && $0.isReady(in: self) }
    }
}

@Model
final class Settings {
    var hasOnboarded: Bool = false
    var roleName: String?

    init() {}
}
