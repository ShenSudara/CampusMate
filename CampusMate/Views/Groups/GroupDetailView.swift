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
            Section {
                GroupAdminCard(admin: group.admin, isCurrentUser: isAdmin)
            }

            memberSection(
                title: "Students",
                subtitle: "Sharing their journeys",
                emptyText: "No members are in Student mode.",
                ids: group.studentIds,
                group: group,
                canRemove: isAdmin
            )

            memberSection(
                title: "Guardians",
                subtitle: "Watching students' journeys",
                emptyText: "No members are in Guardian mode.",
                ids: group.guardianIds,
                group: group,
                canRemove: isAdmin
            )

            if isAdmin && group.memberIds.count > 1 {
                Section {
                    EmptyView()
                } footer: {
                    Text("Swipe left on a member to remove them. Roles change when members switch modes in their profile.")
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
            if viewModel.isWorking {
                ProgressView("Saving…")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
            }
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

    private func memberSection(title: String, subtitle: String, emptyText: String,
                               ids: [String], group: TrustedGroup, canRemove: Bool) -> some View {
        Section {
            if ids.isEmpty {
                Text(emptyText)
                    .foregroundColor(.secondary)
            }
            ForEach(ids, id: \.self) { uid in
                memberRow(uid: uid, group: group)
                    .swipeActions {
                        if canRemove && uid != group.adminId {
                            Button("Remove", role: .destructive) {
                                Task { await viewModel.removeMember(uid, from: group) }
                            }
                        }
                    }
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                Text(subtitle)
                    .textCase(nil)
            }
        }
    }

    private func memberRow(uid: String, group: TrustedGroup) -> some View {
        let member = group.member(uid)
        let mode = group.mode(of: uid)
        return HStack(spacing: 12) {
            Image(systemName: mode.systemImage)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)
                .accessibilityLabel("\(mode.title) mode")
            VStack(alignment: .leading, spacing: 2) {
                Text(member?.displayName ?? "Unknown")
                    + Text(uid == viewModel.currentUserId ? " (You)" : "").foregroundColor(.secondary)
                Text(member?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if group.isAdmin(uid) {
                AdminBadge()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct GroupAdminCard: View {
    let admin: GroupMember?
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Group Admin")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text((admin?.displayName ?? "Unknown") + (isCurrentUser ? " (You)" : ""))
                    .font(.headline)
                Text(admin?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct AdminBadge: View {
    var body: some View {
        Label("Admin", systemImage: "crown.fill")
            .font(.caption2.bold())
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(viewModel: GroupsViewModel(), groupId: "family")
    }
}
