import Foundation
import FirebaseFirestore

final class GroupService {
    static let shared = GroupService()

    private lazy var groups = Firestore.firestore().collection("groups")

    func listenToGroups(for uid: String,
                        onChange: @escaping (Result<[TrustedGroup], Error>) -> Void) -> ListenerRegistration {
        groups.whereField("memberIds", arrayContains: uid).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            let result = (snapshot?.documents ?? [])
                .compactMap { try? $0.data(as: TrustedGroup.self) }
                .sorted { $0.createdAt > $1.createdAt }
            onChange(.success(result))
        }
    }

    func createGroup(name: String, creator: AppUser) async throws {
        let group = TrustedGroup(
            name: name,
            adminId: creator.uid,
            studentId: creator.uid,
            memberIds: [creator.uid],
            members: [creator.uid: GroupMember(email: creator.email,
                                               displayName: creator.displayName,
                                               activeMode: creator.activeMode)],
            createdAt: Date()
        )
        try groups.document().setData(from: group)
    }

    func addMember(_ user: AppUser, to groupId: String) async throws {
        try await groups.document(groupId).updateData([
            "memberIds": FieldValue.arrayUnion([user.uid]),
            "members.\(user.uid)": memberData(for: user)
        ])
    }

    func removeMember(_ uid: String, from groupId: String) async throws {
        try await groups.document(groupId).updateData([
            "memberIds": FieldValue.arrayRemove([uid]),
            "members.\(uid)": FieldValue.delete()
        ])
    }

    // Copies the user's latest name, email and mode into every group they belong to.
    func syncMemberProfile(_ user: AppUser) async throws {
        let snapshot = try await groups.whereField("memberIds", arrayContains: user.uid).getDocuments()
        let batch = Firestore.firestore().batch()
        var hasChanges = false
        for document in snapshot.documents {
            guard let group = try? document.data(as: TrustedGroup.self) else { continue }
            let current = group.members[user.uid]
            if current == GroupMember(email: user.email, displayName: user.displayName, activeMode: user.activeMode) {
                continue
            }
            batch.updateData(["members.\(user.uid)": memberData(for: user)], forDocument: document.reference)
            hasChanges = true
        }
        if hasChanges {
            try await batch.commit()
        }
    }

    private func memberData(for user: AppUser) -> [String: Any] {
        ["email": user.email, "displayName": user.displayName, "activeMode": user.activeMode.rawValue]
    }

    func deleteGroup(_ groupId: String) async throws {
        try await groups.document(groupId).delete()
    }
}
