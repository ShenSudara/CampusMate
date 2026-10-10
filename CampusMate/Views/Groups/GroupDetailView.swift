import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var viewModel: GroupsViewModel
    let groupId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingMember = false
    @State private var confirmLeave = false
    @State private var confirmDelete = false

    var body: some View {
        if let group = viewModel.group(withId: groupId) {
            content(for: group)
        } else {
            EmptyStateView(systemImage: "person.3",
                           title: "Group unavailable",
                           message: "This group was deleted or you are no longer a member.")
        }
    }

    private func content(for group: TrustedGroup) -> some View {
        let isAdmin = group.isAdmin(viewModel.currentUserId)
        return List {
            Section("Student") {
                memberRow(uid: group.studentId, group: group, badge: "Admin")
            }

            Section {
                if group.guardianIds.isEmpty {
                    Text("No guardians yet.")
                        .foregroundColor(.secondary)
                }
                ForEach(group.guardianIds, id: \.self) { uid in
                    memberRow(uid: uid, group: group, badge: nil)
                        .swipeActions {
                            if isAdmin {
                                Button("Remove", role: .destructive) {
                                    Task { await viewModel.removeMember(uid, from: group) }
                                }
                            }
                        }
                }
            } header: {
                Text("Guardians")
            } footer: {
                if isAdmin && !group.guardianIds.isEmpty {
                    Text("Swipe left on a guardian to remove them.")
                }
            }

            if let message = viewModel.successMessage {
                Section { Text(message).foregroundColor(.green) }
            }
            if let message = viewModel.errorMessage {
                Section { Text(message).foregroundColor(.red) }
            }

            Section {
                if isAdmin {
                    Button("Delete Group", role: .destructive) { confirmDelete = true }
                } else {
                    Button("Leave Group", role: .destructive) { confirmLeave = true }
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            if isAdmin {
                Button {
                    isAddingMember = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .accessibilityLabel("Add member")
            }
        }
        .overlay {
            if viewModel.isWorking { ProgressView() }
        }
        .sheet(isPresented: $isAddingMember) {
            AddMemberView(viewModel: viewModel, group: group)
        }
        .confirmationDialog("Leave \(group.name)?", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("Leave Group", role: .destructive) {
                Task { if await viewModel.leave(group) { dismiss() } }
            }
        }
        .confirmationDialog("Delete \(group.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Group", role: .destructive) {
                Task { if await viewModel.delete(group) { dismiss() } }
            }
        } message: {
            Text("All members will lose access to this group.")
        }
        .onAppear {
            viewModel.errorMessage = nil
            viewModel.successMessage = nil
        }
    }

    private func memberRow(uid: String, group: TrustedGroup, badge: String?) -> some View {
        let member = group.member(uid)
        return HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            VStack(alignment: .leading) {
                Text(member?.displayName ?? "Unknown")
                    + Text(uid == viewModel.currentUserId ? " (You)" : "").foregroundColor(.secondary)
                Text(member?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let mode = member?.activeMode {
                    Label("Currently in \(mode.title) mode", systemImage: mode.systemImage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption2.bold())
                    .foregroundColor(.accentColor)
            }
        }
    }
}
