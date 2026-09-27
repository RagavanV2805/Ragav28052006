import SwiftUI
import SwiftData

/// Profile & settings: identity, target role, time budget, notification
/// preferences and data controls.
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \CareerRole.sortOrder) private var roles: [CareerRole]
    @State private var viewModel = ProfileViewModel()
    @State private var showResetConfirm = false
    @State private var showRolePicker = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            if let profile {
                identitySection(profile)
                goalSection(profile)
                learningSection(profile)
                notificationsSection(profile)
                dataSection
                aboutSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.csBackground)
        .navigationTitle("Profile")
        .sheet(isPresented: $showRolePicker) {
            RolePickerSheet(roles: roles, currentSlug: profile?.targetRoleSlug) { slug in
                viewModel.setTargetRole(slug: slug, context: context)
            }
        }
        .confirmationDialog(
            "Reset all progress?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                viewModel.resetProgress(context: context)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears skills, projects, sessions and onboarding. The catalogue stays.")
        }
    }

    // MARK: - Sections

    private func identitySection(_ profile: UserProfile) -> some View {
        Section("About You") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: Binding(
                    get: { profile.name },
                    set: { viewModel.updateName($0, context: context) }
                ))
                .multilineTextAlignment(.trailing)
            }
            LabeledContent("Experience", value: profile.experienceLevel.displayName)
            if !profile.knownLanguages.isEmpty {
                LabeledContent("Languages", value: profile.knownLanguages.joined(separator: ", "))
            }
        }
    }

    private func goalSection(_ profile: UserProfile) -> some View {
        Section("Career Goal") {
            Button {
                showRolePicker = true
            } label: {
                HStack {
                    Text("Target Role")
                    Spacer()
                    Text(roles.first { $0.slug == profile.targetRoleSlug }?.name ?? "Not set")
                        .foregroundStyle(Color.csSecondaryText)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.csSecondaryText)
                }
            }
            .accessibilityIdentifier("profile.changeRole")

            if let targetDate = profile.targetDate {
                LabeledContent("Target date", value: targetDate.formatted(date: .abbreviated, time: .omitted))
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Timeline: \(monthsUntil(profile.targetDate)) months")
                    .font(.subheadline)
                Slider(
                    value: Binding(
                        get: { Double(monthsUntil(profile.targetDate)) },
                        set: { viewModel.updateTimeline(months: Int($0), context: context) }
                    ),
                    in: 1...24,
                    step: 1
                )
            }
        }
    }

    private func learningSection(_ profile: UserProfile) -> some View {
        Section("Learning") {
            Stepper(value: Binding(
                get: { profile.dailyMinutes },
                set: { viewModel.updateDailyMinutes($0, context: context) }
            ), in: 10...480, step: 15) {
                Text("Daily time: \(profile.dailyMinutes) min")
            }
            Text("Recommendations and effort estimates adapt to this.")
                .font(.caption)
                .foregroundStyle(Color.csSecondaryText)
        }
    }

    private func notificationsSection(_ profile: UserProfile) -> some View {
        Section("Notifications") {
            if let preference = profile.notificationPreference {
                Toggle("Daily learning reminder", isOn: Binding(
                    get: { preference.dailyReminderEnabled },
                    set: {
                        preference.dailyReminderEnabled = $0
                        viewModel.savePreferences(preference, context: context)
                    }
                ))
                if preference.dailyReminderEnabled {
                    DatePicker(
                        "Reminder time",
                        selection: Binding(
                            get: { time(from: preference) },
                            set: { setTime($0, on: preference) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
                Toggle("Project deadline reminders", isOn: Binding(
                    get: { preference.deadlineRemindersEnabled },
                    set: {
                        preference.deadlineRemindersEnabled = $0
                        viewModel.savePreferences(preference, context: context)
                    }
                ))
                Toggle("Weekly progress summary", isOn: Binding(
                    get: { preference.weeklySummaryEnabled },
                    set: {
                        preference.weeklySummaryEnabled = $0
                        viewModel.savePreferences(preference, context: context)
                    }
                ))
                Toggle("Inactivity reminder", isOn: Binding(
                    get: { preference.inactivityReminderEnabled },
                    set: {
                        preference.inactivityReminderEnabled = $0
                        viewModel.savePreferences(preference, context: context)
                    }
                ))
            } else {
                Text("Notification settings unavailable.")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Reset All Progress", role: .destructive) {
                showResetConfirm = true
            }
            .accessibilityIdentifier("profile.reset")
            Text("CareerOS is offline-first: everything lives on this device.")
                .font(.caption)
                .foregroundStyle(Color.csSecondaryText)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Roles", value: "\(roles.count) roadmaps")
        }
    }

    // MARK: - Helpers

    private func monthsUntil(_ date: Date?) -> Int {
        guard let date else { return 6 }
        let months = Calendar.current.dateComponents([.month], from: .now, to: date).month ?? 6
        return max(1, min(24, months))
    }

    private func time(from preference: NotificationPreference) -> Date {
        Calendar.current.date(bySettingHour: preference.reminderHour, minute: preference.reminderMinute, second: 0, of: .now) ?? .now
    }

    private func setTime(_ date: Date, on preference: NotificationPreference) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        preference.reminderHour = components.hour ?? preference.reminderHour
        preference.reminderMinute = components.minute ?? preference.reminderMinute
        viewModel.savePreferences(preference, context: context)
    }
}

/// Bottom sheet for changing the target role.
struct RolePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let roles: [CareerRole]
    let currentSlug: String?
    var onSelect: (String) -> Void

    @State private var selection: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                RoleSelectionGrid(
                    selectedSlug: Binding(
                        get: { selection ?? currentSlug },
                        set: { selection = $0 }
                    ),
                    roles: roles
                )
                .padding(DesignSystem.Spacing.md)
            }
            .navigationTitle("Choose Target Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let selection {
                            onSelect(selection)
                        }
                        dismiss()
                    }
                    .disabled(selection == nil)
                }
            }
        }
    }
}
