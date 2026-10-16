import SwiftUI

struct ProfileView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var alertsViewModel: AlertsViewModel
    @State private var editedName = ""
    @State private var isEditingName = false

    var body: some View {
        NavigationStack {
            Form {
                if let user = session.user {
                    Section("Account") {
                        LabeledContent("Name", value: user.displayName)
                        LabeledContent("Email", value: user.email)
                        Button("Edit Name") {
                            editedName = user.displayName
                            isEditingName = true
                        }
                    }

                    Section {
                        ModeSwitcherView(
                            selection: user.activeMode,
                            isSaving: session.isSaving,
                            onSelect: { mode in Task { await session.switchMode(to: mode) } }
                        )
                    } header: {
                        Text("Mode")
                    } footer: {
                        Text(user.activeMode == .student
                             ? "Student mode lets you share your journeys with your trusted groups."
                             : "Guardian mode lets you watch the journeys of students you look after.")
                    }
                }

                Section {
                    notificationRow
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Guardians are notified about missed check-ins and possible emergencies. Students are notified when a guardian checks on them.")
                }

                Section {
                    NavigationLink {
                        SafetySettingsView()
                    } label: {
                        Label("Safety Settings", systemImage: "slider.horizontal.3")
                    }
                } footer: {
                    Text("Adjust check-in time, motion sensitivity and the SOS button. Saved on this device.")
                }

                if let errorMessage = session.errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        session.stop()
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await alertsViewModel.refreshNotificationStatus() }
            .alert("Edit Name", isPresented: $isEditingName) {
                TextField("Full name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { Task { await session.updateDisplayName(editedName) } }
            }
        }
    }

    @ViewBuilder
    private var notificationRow: some View {
        switch alertsViewModel.notificationStatus {
        case .authorized, .provisional, .ephemeral:
            Label("On", systemImage: "bell.badge.fill")
                .foregroundColor(.green)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label("Off", systemImage: "bell.slash.fill")
                    .foregroundColor(.red)
                Text("You won't hear about safety alerts. Turn notifications on in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        default:
            Button("Allow Notifications") {
                Task { await alertsViewModel.requestNotificationPermission() }
            }
        }
    }
}

#Preview {
    ProfileView(session: SessionViewModel(), authViewModel: AuthViewModel(), alertsViewModel: AlertsViewModel())
}
