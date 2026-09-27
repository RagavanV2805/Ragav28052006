# CareerOS — Architecture Notes

This document records the foundational decisions made before implementation.

## 1. Goals & constraints

- Native iOS (Swift + SwiftUI), iOS 17.4+.
- Offline-first: SwiftData is the single source of truth; no network calls.
- Data-driven catalogue: roles/skills/projects/resources are seed data; the
  UI never special-cases a role.
- Testable core: every decision engine is pure value-type code.

## 2. Data model (SwiftData)

```
UserProfile ── NotificationPreference
CareerRole ─┬─ Roadmap ── RoadmapNode ── Skill ─┬─ SkillPrerequisite (edges)
            └─ Project ── ProjectMilestone      ├─ Resource
                                                └─ SkillProgress
Project ── ProjectProgress
LearningSession (per-day activity log)
```

Key decisions:

- **Skills are global.** `RoadmapNode` is the role-specific wrapper carrying
  stage, order, importance (1–5), optionality and target level. This lets a
  single skill (e.g. "SQL") serve many roles with different importance.
- **Prerequisites are explicit edges** (`SkillPrerequisite`) with
  `isRequired`, so optional prerequisites never lock a skill and edges can
  carry metadata later.
- **Progress is keyed by slug** (`SkillProgress.skillSlug`,
  `ProjectProgress.projectSlug`) with `@Attribute(.unique)`, so switching the
  target role never loses history.
- **`LearningSession`** stores one merged record per day; it powers streaks,
  weekly charts and time-spent analytics.

## 3. Domain engines (pure)

| Engine | Input | Output |
| --- | --- | --- |
| `RecommendationEngine` | role nodes as `PlannerSkill`, globally satisfied skill ids, daily minutes | ranked `SkillRecommendation`s with reasons + effort; blocker fallback |
| `RoleMatchCalculator` | role requirement snapshots, user levels/completions | weighted % and matched/in-progress/missing/optional lists |
| `RoadmapProgressCalculator` | node states | weighted overall %, per-stage breakdown |
| `StreakCalculator` | set of active days | streak length + at-risk flag |
| `ProjectEligibilityCalculator` | required skill ids, satisfied ids | eligibility + readiness fraction |

`RoadmapService` is the only bridge between SwiftData models and these
engines, keeping views and engines decoupled.

### Recommendation scoring

```
score = importance × 20
      + unlockCount × 8          (role skills this unblocks)
      + stagePriority (earlier stages first)
      + 10 if required (−12 if optional)
      + 15 if already in progress (momentum)
      − 4 if effort exceeds ~3 weeks at the user's pace
```

A node is *eligible* only when every **required** prerequisite is satisfied
(completed, or rated ≥ its target, anywhere in the app — previous roles count).
When nothing is eligible the engine recommends the highest-leverage blocker.

## 4. Navigation

- Onboarding is a standalone `NavigationStack` (never part of tabs) and ends
  by flipping `UserProfile.hasCompletedOnboarding`.
- Main app: `TabView` (Home, Roadmap, Projects, Analytics, Profile), each tab
  owns a `NavigationPath` inside `AppRouter` (`@Observable`).
- Detail screens are registered once via `.careerDestinations()` so any tab
  can push Skill / Project / Role details.

## 5. MVVM conventions

- ViewModels are `@Observable` classes created with `@State` by their view.
- Reads happen through services (`RoadmapService`, `ActivityService`);
  mutations go through view-model methods which persist, then publish a
  widget snapshot.
- Views receive pre-shaped structs (`DashboardData`, `AnalyticsData`,
  `RoadmapViewModel.Section`) and never run fetches themselves.

## 6. Widgets

- The app serialises a `WidgetSnapshot` (role, %, next skill, streak,
  today's items) into the App Group (`group.com.careeros.shared`) on every
  relevant mutation and calls `WidgetCenter.reloadAllTimelines()`.
- Widget providers are `TimelineProvider`s reading that snapshot — the widget
  process never opens the SwiftData store.

## 7. Notifications

All scheduling goes through the `NotificationService` actor with stable
identifiers:

- `careeros.reminder.daily` (repeating, user-chosen time)
- `careeros.reminder.deadline.<project>` (one-shot, 24h before deadline)
- `careeros.reminder.weekly` (Sunday 18:00)
- `careeros.reminder.inactivity` (one-shot, after 2 idle days)

Preference toggles re-apply the full schedule deterministically.

## 8. Seed data & validation

`SeedService.validate()` runs before inserting and in unit tests:

- unique skill/project slugs,
- all prerequisite/role/project references resolve,
- the prerequisite graph is acyclic (DFS).

## 9. Testing strategy

- Pure engines: value-type fixtures (no DB).
- Integration: seeded in-memory `ModelContainer`
  (`PersistenceService.makeInMemoryContainer`).
- UI: `-uitest` launch flag wipes the store and disables notification
  scheduling for determinism.

## 10. Extensibility

- New role: one `RoleSeed` entry (+ optional new skills/projects).
- New resource kinds: extend `ResourceKind`.
- New stages: extend `RoadmapStage` — sections, charts and summaries follow.
- Cloud sync: confined to `PersistenceService` (swap/extend container).
