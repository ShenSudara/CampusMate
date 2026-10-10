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
                    Text("The person must already have a CampusMate account. They will be added as a guardian of \(group.name).")
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
