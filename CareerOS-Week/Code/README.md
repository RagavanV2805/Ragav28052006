# CareerOS — Simple Edition 🚀

A **one-week, simple version** of the CareerOS idea:

> Pick a career goal → see a small roadmap → skills unlock when their
> prerequisites are done → build the matching project → track progress.

Built with **SwiftUI + SwiftData**, 8 small files, no frameworks beyond
what Xcode gives you. Works fully offline.

## What's inside

| File | Purpose |
| --- | --- |
| `CareerOSApp.swift` | App entry, seeding, tabs |
| `Models.swift` | 4 tiny SwiftData models (Skill, Project, Role, Settings) |
| `SeedData.swift` | 3 roles with ordered skills + prerequisites + projects |
| `OnboardingView.swift` | One screen: choose your goal |
| `DashboardView.swift` | Progress + "learn next" + ready project |
| `RoadmapView.swift` | Skills grouped by stage, lock/unlock logic |
| `ProjectsView.swift` | Projects that unlock with your skills |
| `ProfileView.swift` | Switch role / reset |

## Run it (5 minutes)

1. Xcode → **File ▸ New ▸ Project ▸ iOS App**, name it `CareerOS`,
   Interface: *SwiftUI*, Storage: *None* (we create the container ourselves).
   iOS 17+.
2. Delete the template `ContentView.swift` and the `...App.swift` file.
3. Drag all the `.swift` files from this folder into the project.
4. Run on any iPhone simulator.

That's it — no packages, no extra setup.
