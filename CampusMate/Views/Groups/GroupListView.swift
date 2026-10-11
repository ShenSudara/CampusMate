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
                } else if viewModel.groups.isEmpty {
                    EmptyStateView(
                        systemImage: "person.3",
                        title: "No groups yet",
                        message: "Create a trusted group and add the people who should watch over your journeys."
                    )
                } else {
                    List {
                        if !viewModel.myGroups.isEmpty {
                            Section("My Groups") {
                                ForEach(viewModel.myGroups) { group in
                                    row(for: group)
                                }
                            }
                        }
                        if !viewModel.guardingGroups.isEmpty {
                            Section("Students I Guard") {
                                ForEach(viewModel.guardingGroups) { group in
                                    row(for: group)
                                }
                            }
                        }
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
                    if group.isAdmin(viewModel.currentUserId) {
                        Text("Admin")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                Text(group.studentId == viewModel.currentUserId
                     ? "\(group.guardianIds.count) guardian(s)"
                     : "Protecting \(group.studentName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    GroupListView(viewModel: GroupsViewModel(), session: SessionViewModel())
}
