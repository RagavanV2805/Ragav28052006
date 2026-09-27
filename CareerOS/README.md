# CareerOS

A production-quality, offline-first iOS application that turns "I want to be
a software engineer" into a concrete, personalised plan.

Pick a **target role**, tell CareerOS what you already know, and get:

- a personalised **roadmap** with prerequisite-aware skill ordering,
- a **"what should I learn next"** engine with reasons, not just checklists,
- **Role Match** — transparent coverage of every supported role,
- **project recommendations** that unlock as your skills grow,
- **analytics** (streaks, weekly activity, category progress) via Swift Charts,
- **widgets** that keep today's focus on your Home Screen,
- local **notifications** for reminders, deadlines and weekly summaries.

Built with **Swift, SwiftUI, SwiftData, MVVM, Swift Charts, WidgetKit,
UserNotifications and structured concurrency**. No network access is ever
required.

---

## Supported roles (14)

Software Engineer · Full Stack Developer · Backend Developer · Frontend
Developer · iOS Developer · Android Developer · Data Analyst · Data Scientist
· Machine Learning Engineer · AI Engineer · Cloud Engineer · DevOps Engineer ·
Cybersecurity Engineer · QA Automation Engineer

Roles are pure data (`Data/RoleCatalogue.swift`). Adding a role means adding
one `RoleSeed` entry that references existing skill slugs — no UI changes.

---

## Getting started

### Requirements

- Xcode 15.4+ (iOS 17.4 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (keeps `.xcodeproj`
  out of source control)

### Build & run

```bash
cd CareerOS
brew install xcodegen        # one-time
xcodegen generate            # creates CareerOS.xcodeproj
open CareerOS.xcodeproj
```

Select the **CareerOS** scheme and an iPhone simulator (iOS 17.4+) and run.

### Tests

```bash
xcodebuild test -project CareerOS.xcodeproj -scheme CareerOS \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Unit tests cover the recommendation engine, role matching, prerequisite
resolution, roadmap progress, project progress, streaks and persistence.
UI tests walk the critical journey: Onboarding → Role selection → Assessment
→ Roadmap → Skill completion → Dashboard update.

---

## Feature tour

| Area | Highlights |
| --- | --- |
| Onboarding | Experience, known languages, skill ratings (0–5), DSA & CS levels, time budget, target role, timeline, confidence |
| Dashboard | Goal progress ring, streak, "Learn next" card with expandable reasons, current project, weekly activity chart, deadlines, recent completions |
| Roadmap | Stage-grouped nodes with Locked / Available / In Progress / Completed states, prerequisite connectors, search, filters, per-role preview |
| Skill detail | Level control, importance, prerequisites, unlocks, structured resources, suggested projects, notes, log time |
| Projects | Recommended (skills satisfied), Almost Ready, saved projects with milestones, deadlines, notes, pause/resume/complete |
| Role Match | Weighted % per role with matched / in-progress / missing / optional breakdowns |
| Analytics | Roadmap %, weekly minutes, cumulative completions, category breakdown, streak, total time |
| Widgets | Small/medium "Next Skill", medium "Today's Roadmap" |
| Notifications | Daily reminder, deadline reminder (−24h), weekly summary, inactivity nudge — all configurable |

---

## Architecture

```
CareerOS/
├── project.yml              # XcodeGen specification (targets, schemes)
├── CareerOS/                # App target
│   ├── App/                 # Entry point, router, tab shell
│   ├── Models/              # SwiftData @Model types + enums
│   ├── Services/            # Engines (pure), persistence, notifications,
│   │                        #   activity, widget publishing, roadmap bridge
│   ├── ViewModels/          # @Observable MVVM view models
│   ├── Views/               # Onboarding / Dashboard / Roadmap / Skills /
│   │                        #   Roles / Projects / Analytics / Profile
│   ├── Components/          # Reusable cards, charts, pickers, state views
│   ├── Data/                # Seed catalogue (skills, roles, projects)
│   └── Utilities/           # Design system, UI-test mode
├── CareerOSWidgets/         # WidgetKit extension (small + medium widgets)
├── Shared/                  # WidgetSnapshot shared between app and widgets
├── CareerOSTests/           # Unit tests
└── CareerOSUITests/         # UI tests for the critical journey
```

### Layering rules

1. **Views** present values and forward intent — no fetching, no business
   logic.
2. **ViewModels** (`@Observable`) orchestrate services for a screen.
3. **Services** bridge SwiftData to **pure engines**. The recommendation
   engine, role matcher, progress calculator and streak calculator operate on
   value types (`PlannerSkill`, `RoleRequirementSnapshot`, …) so they are
   deterministic and unit-tested without a database.
4. **Models** are SwiftData `@Model` classes with real relationships —
   `CareerRole → Roadmap → RoadmapNode → Skill ← SkillPrerequisite → Skill`,
   `Skill ← Resource`, `Project → ProjectMilestone`, and user-side
   `UserProfile`, `SkillProgress`, `ProjectProgress`, `LearningSession`,
   `NotificationPreference`.

### The recommendation engine in one paragraph

For the target role, every unmet roadmap node whose **required prerequisites
are satisfied** (by completion or by rating ≥ target anywhere in the app) is
scored by `importance × 20 + unlocks × 8 + stage priority + momentum`,
penalised for optional status and very long efforts, then ranked. The top
candidate is presented with human-readable reasons and an effort estimate
derived from the user's daily time budget. If nothing is eligible, the engine
recommends the highest-leverage *blocker* instead — it never recommends a
skill ahead of its important prerequisites.

### Offline-first & sync-ready

SwiftData is the single source of truth; every feature works with airplane
mode on. All mutations flow through `PersistenceService`, so adding CloudKit
sync later is a contained change.

### Widgets

The app publishes a compact `WidgetSnapshot` (JSON) to the App Group store on
every relevant mutation; widget providers read it without touching SwiftData,
and `WidgetCenter.reloadAllTimelines()` keeps them fresh.

---

## Design system

Tokens live in `Utilities/DesignSystem.swift` (spacing, radii, shadows) plus
semantic colors that adapt to dark mode automatically. Components (`SkillCard`,
`ProjectCard`, `ResourceRow`, `ProgressRing`, `StatTile`, `ChipView`,
`EmptyStateView`, `LoadingView`, `ErrorStateView`, `LevelPicker`) are reused
across screens. Typography uses Dynamic Type throughout; interactive cards
merge their children for VoiceOver and carry labels, values and hints.

---

## Adding a role (data-only change)

1. Add any new skills to `Data/SkillCatalogue.swift` (slug, summary,
   prerequisites, resources).
2. Add a `RoleSeed` to `Data/RoleCatalogue.swift` listing node slugs with
   stage, importance and target level.
3. Optionally attach projects in `Data/ProjectCatalogue.swift`.
4. Delete the app (or let `SeedService` run on a fresh install) — the UI,
   recommendation engine, role matching and search pick it up automatically.

`SeedService.validate()` (run at seed time and in unit tests) guarantees slug
referential integrity and an acyclic prerequisite graph.
