import SwiftUI

struct AddMemberView: View {
    @ObservedObject var viewModel: GroupsViewModel
    let group: TrustedGroup
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("The person must already have a CampusMate account. Their role in \(group.name) follows the mode they choose in their profile.")
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isWorking {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task {
                                if await viewModel.addMember(email: email, to: group) {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!InputValidator.isValidEmail(email))
                    }
                }
            }
            .onAppear { viewModel.errorMessage = nil }
        }
    }
}

#Preview {
    AddMemberView(
        viewModel: GroupsViewModel(),
        group: TrustedGroup(
            id: "family",
            name: "Family",
            adminId: "alex",
            memberIds: ["alex", "maya"],
            members: [
                "alex": GroupMember(email: "alex@example.com", displayName: "Alex Perera", activeMode: .student),
                "maya": GroupMember(email: "maya@example.com", displayName: "Maya Perera", activeMode: .guardian)
            ],
            createdAt: Date()
        )
    )
}
