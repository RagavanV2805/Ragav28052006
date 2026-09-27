import SwiftUI
import SwiftData

/// One screen: pick your goal role and start.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Role.name) private var roles: [Role]
    @State private var selected: Role?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("CareerOS")
                    .font(.largeTitle.bold())
                Text("Pick a goal. Get a simple roadmap.\nLearn one skill at a time.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                ForEach(roles) { role in
                    Button {
                        selected = role
                    } label: {
                        HStack {
                            Image(systemName: role.icon)
                            Text(role.name).fontWeight(.medium)
                            Spacer()
                            Image(systemName: selected?.name == role.name
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected?.name == role.name ? .blue : .secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected?.name == role.name
                                      ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button("Start Learning") {
                    guard let selected else { return }
                    let settings = Settings()
                    settings.roleName = selected.name
                    settings.hasOnboarded = true
                    context.insert(settings)
                    try? context.save()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selected == nil)
            }
            .padding()
        }
    }
}
