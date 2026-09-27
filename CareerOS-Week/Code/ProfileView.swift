import SwiftUI
import SwiftData

/// Change your goal role or start over. Progress is kept per role,
/// so switching never deletes what you learned.
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Role.name) private var roles: [Role]
    @Query private var settingsList: [Settings]

    var body: some View {
        Form {
            Section("Goal Role") {
                Picker("Target role", selection: Binding(
                    get: { settingsList.first?.roleName ?? "" },
                    set: { newValue in
                        settingsList.first?.roleName = newValue
                        try? context.save()
                    }
                )) {
                    ForEach(roles) { role in
                        Text(role.name).tag(role.name)
                    }
                }
            }

            Section {
                Button("Reset Progress", role: .destructive) {
                    for role in roles {
                        for skill in role.skills { skill.isDone = false }
                        for project in role.projects { project.isDone = false }
                    }
                    try? context.save()
                }
            } footer: {
                Text("CareerOS (simple edition) — offline-first, all data stays on your device.")
            }
        }
        .navigationTitle("Profile")
    }
}
