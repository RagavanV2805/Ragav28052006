import Foundation

// MARK: - Skill Category

/// Broad functional grouping used for filtering, analytics and styling.
enum SkillCategory: String, Codable, CaseIterable, Identifiable {
    case fundamentals
    case language
    case dataStructuresAlgorithms
    case computerScience
    case web
    case mobile
    case dataAndDatabases
    case dataScienceML
    case cloudDevOps
    case security
    case testing
    case architecture
    case tools
    case career

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fundamentals: return "Fundamentals"
        case .language: return "Programming Language"
        case .dataStructuresAlgorithms: return "DSA"
        case .computerScience: return "CS Fundamentals"
        case .web: return "Web"
        case .mobile: return "Mobile"
        case .dataAndDatabases: return "Data & Databases"
        case .dataScienceML: return "Data Science & ML"
        case .cloudDevOps: return "Cloud & DevOps"
        case .security: return "Security"
        case .testing: return "Testing & QA"
        case .architecture: return "Design & Architecture"
        case .tools: return "Tools"
        case .career: return "Career"
        }
    }

    var symbolName: String {
        switch self {
        case .fundamentals: return "foundation"
        case .language: return "chevron.left.forwardslash.chevron.right"
        case .dataStructuresAlgorithms: return "point.3.connected.trianglepath.dotted"
        case .computerScience: return "desktopcomputer"
        case .web: return "globe"
        case .mobile: return "smartphone"
        case .dataAndDatabases: return "cylinder.split.1x2"
        case .dataScienceML: return "brain"
        case .cloudDevOps: return "cloud"
        case .security: return "lock.shield"
        case .testing: return "checkmark.seal"
        case .architecture: return "building.columns"
        case .tools: return "wrench.and.screwdriver"
        case .career: return "briefcase"
        }
    }
}

// MARK: - Roadmap Stage

/// Ordered phases of a role roadmap. Nodes carry `orderIndex` inside a stage
/// to express the recommended learning order.
enum RoadmapStage: Int, Codable, CaseIterable, Identifiable, Comparable {
    case fundamentals = 0
    case coreSkills = 1
    case advancedSkills = 2
    case tools = 3
    case frameworks = 4
    case projects = 5
    case interviewPrep = 6

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fundamentals: return "Fundamentals"
        case .coreSkills: return "Core Skills"
        case .advancedSkills: return "Advanced Skills"
        case .tools: return "Tools"
        case .frameworks: return "Frameworks"
        case .projects: return "Projects"
        case .interviewPrep: return "Interview Preparation"
        }
    }

    var symbolName: String {
        switch self {
        case .fundamentals: return "foundation"
        case .coreSkills: return "square.stack.3d.up"
        case .advancedSkills: return "arrow.up.right.circle"
        case .tools: return "wrench.and.screwdriver"
        case .frameworks: return "square.grid.2x2"
        case .projects: return "hammer"
        case .interviewPrep: return "person.2.wave.2"
        }
    }

    static func < (lhs: RoadmapStage, rhs: RoadmapStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Skill Status

enum SkillStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Skill Level (0...5 self rating)

/// 0 = Not started, 1 = Beginner, 2 = Basic, 3 = Intermediate,
/// 4 = Advanced, 5 = Strong.
enum SkillLevel: Int, Codable, CaseIterable, Identifiable {
    case notStarted = 0
    case beginner = 1
    case basic = 2
    case intermediate = 3
    case advanced = 4
    case strong = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .notStarted: return "Not started"
        case .beginner: return "Beginner"
        case .basic: return "Basic"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .strong: return "Strong"
        }
    }

    init(clamping value: Int) {
        self = SkillLevel(rawValue: min(max(value, 0), 5)) ?? .notStarted
    }
}

// MARK: - Project

enum ProjectDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var sortOrder: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case paused
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Resources

enum ResourceKind: String, Codable, CaseIterable, Identifiable {
    case documentation
    case article
    case video
    case course
    case practice
    case book

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .documentation: return "Documentation"
        case .article: return "Article"
        case .video: return "Video"
        case .course: return "Course"
        case .practice: return "Practice Platform"
        case .book: return "Book"
        }
    }

    var symbolName: String {
        switch self {
        case .documentation: return "doc.text"
        case .article: return "newspaper"
        case .video: return "play.rectangle"
        case .course: return "graduationcap"
        case .practice: return "keyboard"
        case .book: return "book.closed"
        }
    }
}

// MARK: - Experience & Onboarding

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case student
    case earlyCareer
    case selfTaught
    case bootcampGraduate
    case workingProfessional

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .student: return "Student"
        case .earlyCareer: return "Early-career developer"
        case .selfTaught: return "Self-taught"
        case .bootcampGraduate: return "Bootcamp graduate"
        case .workingProfessional: return "Working professional"
        }
    }
}
