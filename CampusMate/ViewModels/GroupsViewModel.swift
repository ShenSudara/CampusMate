import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class GroupsViewModel: ObservableObject {
    @Published private(set) var groups: [TrustedGroup] = []
    @Published private(set) var isLoading = true
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let groupService: GroupService
    private let userService: UserService
    private var listener: ListenerRegistration?
    private var uid: String?

    init(groupService: GroupService = .shared, userService: UserService = .shared) {
        self.groupService = groupService
        self.userService = userService
    }

    var currentUserId: String { uid ?? "" }

    func group(withId id: String?) -> TrustedGroup? {
        groups.first { $0.id == id }
    }

    func start(uid: String) {
        guard listener == nil else { return }
        self.uid = uid
        listener = groupService.listenToGroups(for: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let groups):
                    self.groups = groups
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
                self.isLoading = false
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        groups = []
        isLoading = true
    }

    func createGroup(name: String, creator: AppUser?) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let creator, !trimmed.isEmpty else {
            errorMessage = "Please enter a group name."
            return false
        }
        return await perform { try await self.groupService.createGroup(name: trimmed, creator: creator) }
    }

    func addMember(email: String, to group: TrustedGroup) async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard InputValidator.isValidEmail(trimmed) else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        guard let groupId = group.id, group.isAdmin(currentUserId) else {
            errorMessage = "Only the group admin can add members."
            return false
        }
        return await perform {
            guard let user = try await self.userService.findUser(byEmail: trimmed) else {
                throw AppError.message("No CampusMate account uses \(trimmed). Ask them to sign up first.")
            }
            if group.memberIds.contains(user.uid) {
                throw AppError.message("\(user.displayName) is already in this group.")
            }
            try await self.groupService.addMember(user, to: groupId)
            self.successMessage = "\(user.displayName) was added to \(group.name)."
        }
    }

    func removeMember(_ memberId: String, from group: TrustedGroup) async {
        guard let groupId = group.id else { return }
        guard group.isAdmin(currentUserId), memberId != group.adminId else {
            errorMessage = "Only the admin can remove other members."
            return
        }
        _ = await perform { try await self.groupService.removeMember(memberId, from: groupId) }
    }

    func leave(_ group: TrustedGroup) async -> Bool {
        guard let groupId = group.id, !group.isAdmin(currentUserId) else { return false }
        return await perform { try await self.groupService.removeMember(self.currentUserId, from: groupId) }
    }

    func delete(_ group: TrustedGroup) async -> Bool {
        guard let groupId = group.id, group.isAdmin(currentUserId) else { return false }
        return await perform { try await self.groupService.deleteGroup(groupId) }
    }

    private func perform(_ action: @escaping () async throws -> Void) async -> Bool {
        isWorking = true
        errorMessage = nil
        successMessage = nil
        defer { isWorking = false }
        do {
            try await action()
            return true
        } catch {
            errorMessage = AppError.userMessage(for: error)
            return false
        }
    }
}
