import SwiftData

/// Small bundled dataset: 3 roles, ordered skills with prerequisites,
/// and a couple of projects each. Runs once on first launch.
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        var check = FetchDescriptor<Role>()
        check.fetchLimit = 1
        if (try? context.fetch(check))?.first != nil { return }

        // MARK: iOS Developer
        let ios = Role(name: "iOS Developer", icon: "iphone")
        ios.skills = [
            Skill(name: "Swift Basics", stage: "Basics", hours: 20),
            Skill(name: "SwiftUI Views", stage: "Basics", hours: 15, prereqs: ["Swift Basics"]),
            Skill(name: "Lists & Navigation", stage: "Core", hours: 10, prereqs: ["SwiftUI Views"]),
            Skill(name: "State & Bindings", stage: "Core", hours: 10, prereqs: ["SwiftUI Views"]),
            Skill(name: "Networking", stage: "Core", hours: 12, prereqs: ["Swift Basics"]),
            Skill(name: "Local Storage", stage: "Advanced", hours: 10, prereqs: ["SwiftUI Views"]),
            Skill(name: "App Store Release", stage: "Advanced", hours: 6, prereqs: ["Networking", "Local Storage"]),
        ]
        ios.projects = [
            Project(title: "To-Do List App", difficulty: "Beginner", required: ["SwiftUI Views"]),
            Project(title: "Weather App", difficulty: "Intermediate", required: ["Networking", "Lists & Navigation"]),
            Project(title: "Habit Tracker", difficulty: "Advanced", required: ["Local Storage", "State & Bindings"]),
        ]

        // MARK: Full Stack Developer
        let full = Role(name: "Full Stack Developer", icon: "square.stack.3d.up")
        full.skills = [
            Skill(name: "HTML & CSS", stage: "Basics", hours: 15),
            Skill(name: "JavaScript", stage: "Basics", hours: 25, prereqs: ["HTML & CSS"]),
            Skill(name: "React", stage: "Core", hours: 20, prereqs: ["JavaScript"]),
            Skill(name: "Node.js", stage: "Core", hours: 15, prereqs: ["JavaScript"]),
            Skill(name: "SQL", stage: "Core", hours: 12),
            Skill(name: "REST APIs", stage: "Advanced", hours: 10, prereqs: ["Node.js"]),
            Skill(name: "Auth & Deploy", stage: "Advanced", hours: 10, prereqs: ["REST APIs", "SQL"]),
        ]
        full.projects = [
            Project(title: "Portfolio Site", difficulty: "Beginner", required: ["HTML & CSS"]),
            Project(title: "Task Manager", difficulty: "Intermediate", required: ["React", "REST APIs"]),
            Project(title: "E-commerce Store", difficulty: "Advanced", required: ["Auth & Deploy"]),
        ]

        // MARK: Data Analyst
        let data = Role(name: "Data Analyst", icon: "chart.bar.xaxis")
        data.skills = [
            Skill(name: "Spreadsheets", stage: "Basics", hours: 8),
            Skill(name: "SQL", stage: "Basics", hours: 15),
            Skill(name: "Python", stage: "Core", hours: 20),
            Skill(name: "Pandas", stage: "Core", hours: 12, prereqs: ["Python"]),
            Skill(name: "Statistics", stage: "Core", hours: 15),
            Skill(name: "Dashboards", stage: "Advanced", hours: 10, prereqs: ["SQL", "Spreadsheets"]),
            Skill(name: "A/B Testing", stage: "Advanced", hours: 8, prereqs: ["Statistics"]),
        ]
        data.projects = [
            Project(title: "Sales Dashboard", difficulty: "Beginner", required: ["Spreadsheets", "SQL"]),
            Project(title: "Data Cleanup Report", difficulty: "Intermediate", required: ["Pandas"]),
            Project(title: "A/B Test Analysis", difficulty: "Advanced", required: ["Statistics", "Pandas"]),
        ]

        for role in [ios, full, data] { context.insert(role) }
        context.insert(Settings())
        try? context.save()
    }
}
