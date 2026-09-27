import SwiftUI
import SwiftData

/// The roadmap: skills grouped by stage. Locked skills stay locked until
/// their prerequisites are marked done.
struct RoadmapView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Role.name) private var roles: [Role]
    @Query private var settingsList: [Settings]

    private var role: Role? {
        roles.first { $0.name == settingsList.first?.roleName }
    }

    private var stages: [String] {
        guard let role else { return [] }
        var seen: [String] = []
        for skill in role.skills where !seen.contains(skill.stage) {
            seen.append(skill.stage)
        }
        return seen
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let role {
                    ForEach(stages, id: \.self) { stage in
                        Text(stage)
                            .font(.title3.bold())
                        ForEach(role.skills.filter { $0.stage == stage }) { skill in
                            row(skill, in: role)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Roadmap")
    }

    private func row(_ skill: Skill, in role: Role) -> some View {
        let unlocked = skill.isUnlocked(in: role)
        return Button {
            guard unlocked else { return }
            skill.isDone.toggle()
            try? context.save()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon(for: skill, unlocked: unlocked))
                    .foregroundStyle(color(for: skill, unlocked: unlocked))
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .fontWeight(.medium)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    Text("\(skill.hours)h" + (unlocked ? "" : " • finish prerequisites first"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if skill.isDone {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: 14))
            .opacity(unlocked ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }

    private func icon(for skill: Skill, unlocked: Bool) -> String {
        if skill.isDone { return "checkmark.circle.fill" }
        return unlocked ? "circle.dashed" : "lock.fill"
    }

    private func color(for skill: Skill, unlocked: Bool) -> Color {
        if skill.isDone { return .green }
        return unlocked ? .blue : .secondary
    }
}
