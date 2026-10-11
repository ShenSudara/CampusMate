import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: GroupsViewModel
    let creator: AppUser?
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group name (e.g. Family)", text: $name)
                } footer: {
                    Text("You will be the admin of this group. Members in Student mode share their journeys with the group, and members in Guardian mode watch them.")
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isWorking {
                        ProgressView()
                    } else {
                        Button("Create") {
                            Task {
                                if await viewModel.createGroup(name: name, creator: creator) {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .onAppear { viewModel.errorMessage = nil }
        }
    }
}

#Preview {
    CreateGroupView(
        viewModel: GroupsViewModel(),
        creator: AppUser(id: "alex", email: "alex@example.com", displayName: "Alex Perera",
                     activeMode: .student, createdAt: Date())
    )
}
