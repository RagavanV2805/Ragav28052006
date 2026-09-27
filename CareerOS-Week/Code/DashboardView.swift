import SwiftUI
import SwiftData

/// Home: progress, the one skill to learn next, and a ready project.
struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Role.name) private var roles: [Role]
    @Query private var settingsList: [Settings]

    private var role: Role? {
        roles.first { $0.name == settingsList.first?.roleName }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let role {
                    goalCard(role)
                    nextSkillCard(role)
                    projectCard(role)
                } else {
                    Text("Pick a role in Profile to begin.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("CareerOS")
    }

    private func goalCard(_ role: Role) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: role.icon).foregroundStyle(.blue)
                Text(role.name).font(.headline)
                Spacer()
                Text("\(Int(role.progress * 100))%")
                    .font(.headline).foregroundStyle(.blue)
            }
            ProgressView(value: role.progress)
                .tint(.blue)
            Text("\(role.doneCount) of \(role.skills.count) skills done")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func nextSkillCard(_ role: Role) -> some View {
        if let next = role.nextSkill {
            VStack(alignment: .leading, spacing: 8) {
                Text("LEARN NEXT")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Text("Learn \(next.name) next")
                    .font(.title3.bold())
                Text("About \(next.hours) hours of effort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    next.isDone = true
                    try? context.save()
                } label: {
                    Label("Mark as Learned", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: 16))
        } else {
            Label("Roadmap complete — great work!", systemImage: "trophy")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground),
                            in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func projectCard(_ role: Role) -> some View {
        if let project = role.nextProject {
            VStack(alignment: .leading, spacing: 6) {
                Text("PROJECT FOR YOU")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Text(project.title).font(.headline)
                Text("\(project.difficulty) • you have the skills for it")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
