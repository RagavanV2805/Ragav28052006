import Foundation
import SwiftData

/// Owns the SwiftData stack and offers small, focused helpers that the rest
/// of the app uses instead of repeating fetch/upsert boilerplate. Swapping
/// the backing store (e.g. adding CloudKit sync later) only touches here.
enum PersistenceService {

    /// All model types in the schema, listed explicitly so migrations stay
    /// deliberate.
    static let schema = Schema([
        UserProfile.self,
        NotificationPreference.self,
        CareerRole.self,
        Roadmap.self,
        RoadmapNode.self,
        Skill.self,
        SkillPrerequisite.self,
        Resource.self,
        Project.self,
        ProjectMilestone.self,
        SkillProgress.self,
        ProjectProgress.self,
        LearningSession.self,
    ])

    static func makeContainer() -> ModelContainer {
        if UITestMode.isActive {
            removeStoreFiles()
        }
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            try SeedService.seedIfNeeded(context: container.mainContext)
            return container
        } catch {
            // A corrupt store is unrecoverable at launch; rebuild it once.
            // (Deleting the store loses only local data, which is derived
            // from seed content plus user progress.)
            do {
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                try FileManager.default.removeItem(at: url)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                try SeedService.seedIfNeeded(context: container.mainContext)
                return container
            } catch {
                fatalError("Failed to initialise the SwiftData store: \(error)")
            }
        }
    }

    /// Deletes the on-disk store so UI tests always launch into a fresh app.
    private static func removeStoreFiles() {
        let directory = URL.applicationSupportDirectory
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: directory.appending(path: name))
        }
    }

    static func makeInMemoryContainer(seeded: Bool = true) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        if seeded {
            try SeedService.seedIfNeeded(context: container.mainContext)
        }
        return container
    }

    // MARK: - Profile

    static func profile(in context: ModelContext) -> UserProfile {
        if let existing = fetchOne(UserProfile.self, in: context) {
            return existing
        }
        let profile = UserProfile()
        profile.notificationPreference = NotificationPreference()
        context.insert(profile)
        return profile
    }

    // MARK: - Skills & progress

    static func skill(slug: String, in context: ModelContext) -> Skill? {
        let slugCopy = slug
        return fetchOne(Skill.self, in: context, predicate: #Predicate { $0.slug == slugCopy })
    }

    static func role(slug: String, in context: ModelContext) -> CareerRole? {
        let slugCopy = slug
        return fetchOne(CareerRole.self, in: context, predicate: #Predicate { $0.slug == slugCopy })
    }

    /// Fetch-or-create progress for a skill slug.
    static func skillProgress(forSkillSlug slug: String, in context: ModelContext) -> SkillProgress {
        let slugCopy = slug
        if let existing = fetchOne(SkillProgress.self, in: context, predicate: #Predicate { $0.skillSlug == slugCopy }) {
            return existing
        }
        let progress = SkillProgress(skillSlug: slug)
        progress.skill = skill(slug: slug, in: context)
        context.insert(progress)
        return progress
    }

    static func projectProgress(forProjectSlug slug: String, in context: ModelContext) -> ProjectProgress {
        let slugCopy = slug
        if let existing = fetchOne(ProjectProgress.self, in: context, predicate: #Predicate { $0.projectSlug == slugCopy }) {
            return existing
        }
        let progress = ProjectProgress(projectSlug: slug)
        progress.project = fetchOne(Project.self, in: context, predicate: #Predicate { $0.slug == slugCopy })
        context.insert(progress)
        return progress
    }

    /// Adds a learning session, merging with any existing session that day.
    @discardableResult
    static func logLearningSession(minutes: Int, skillSlug: String?, on date: Date = .now, in context: ModelContext) -> LearningSession {
        let day = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
        let descriptor = FetchDescriptor<LearningSession>(
            predicate: #Predicate { $0.day >= day && $0.day < nextDay }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.minutes += minutes
            existing.skillSlug = skillSlug ?? existing.skillSlug
            return existing
        }
        let session = LearningSession(day: day, minutes: minutes, skillSlug: skillSlug)
        context.insert(session)
        return session
    }

    // MARK: - Generic helpers

    static func fetchOne<T: PersistentModel>(
        _ type: T.Type,
        in context: ModelContext,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    static func fetchAll<T: PersistentModel>(
        _ type: T.Type,
        in context: ModelContext,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        return (try? context.fetch(descriptor)) ?? []
    }
}
