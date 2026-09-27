import SwiftUI
import SwiftData

/// Projects unlock when their required skills are done.
struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Role.name) private var roles: [Role]
    @Query private var settingsList: [Settings]

    private var role: Role? {
        roles.first { $0.name == settingsList.first?.roleName }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let role {
                    ForEach(role.projects) { project in
                        row(project, in: role)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Projects")
    }

    private func row(_ project: Project, in role: Role) -> some View {
        let ready = project.isReady(in: role)
        return Button {
            guard ready || project.isDone else { return }
            project.isDone.toggle()
            try? context.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: project.isDone ? "checkmark.circle.fill"
                              : ready ? "hammer.fill" : "lock.fill")
                    .foregroundStyle(project.isDone ? .green : ready ? .orange : .secondary)
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .fontWeight(.medium)
                        .foregroundStyle(ready || project.isDone ? .primary : .secondary)
                    Text(project.difficulty + (ready || project.isDone
                         ? "" : " • learn the required skills first"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: 14))
            .opacity(ready || project.isDone ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }
}
