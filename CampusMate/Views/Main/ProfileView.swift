import SwiftUI

struct ProfileView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var authViewModel: AuthViewModel
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
            .alert("Edit Name", isPresented: $isEditingName) {
                TextField("Full name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { Task { await session.updateDisplayName(editedName) } }
            }
        }
    }
}

#if DEBUG
#Preview {
    ProfileView(session: .preview(), authViewModel: .preview(isSignedIn: true))
}
#endif
