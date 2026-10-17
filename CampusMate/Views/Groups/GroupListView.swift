import SwiftUI

struct GroupListView: View {
    @ObservedObject var viewModel: GroupsViewModel
    @ObservedObject var session: SessionViewModel
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading groups…")
                } else if let errorMessage = viewModel.errorMessage, viewModel.groups.isEmpty {
                    EmptyStateView(
                        systemImage: "exclamationmark.triangle",
                        title: "Couldn't load groups",
                        message: errorMessage
                    )
                } else if viewModel.groups.isEmpty {
                    EmptyStateView(
                        systemImage: "person.3",
                        title: "No groups yet",
                        message: "Create a trusted group and add the people who should watch over your journeys."
                    )
                } else {
                    List(viewModel.groups) { group in
                        row(for: group)
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create group")
            }
            .sheet(isPresented: $isCreating) {
                CreateGroupView(viewModel: viewModel, creator: session.user)
            }
        }
    }

    private func row(for group: TrustedGroup) -> some View {
        NavigationLink {
            GroupDetailView(viewModel: viewModel, groupId: group.id)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name).font(.headline)
                    Spacer()
                    if group.isAdmin(viewModel.currentUserId) {
                        AdminBadge()
                    }
                }
                Label("Admin: \(group.admin?.displayName ?? "Unknown")", systemImage: "crown")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Label("\(group.studentIds.count)", systemImage: UserMode.student.systemImage)
                        .accessibilityLabel("\(group.studentIds.count) students")
                    Label("\(group.guardianIds.count)", systemImage: UserMode.guardian.systemImage)
                        .accessibilityLabel("\(group.guardianIds.count) guardians")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    GroupListView(viewModel: GroupsViewModel(), session: SessionViewModel())
}
