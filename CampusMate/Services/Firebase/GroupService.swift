import Foundation
import FirebaseFirestore

final class GroupService {
    static let shared = GroupService()

    private let groups = Firestore.firestore().collection("groups")

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
            members: [creator.uid: GroupMember(email: creator.email, displayName: creator.displayName)],
            createdAt: Date()
        )
        try groups.document().setData(from: group)
    }

    func addMember(_ user: AppUser, to groupId: String) async throws {
        try await groups.document(groupId).updateData([
            "memberIds": FieldValue.arrayUnion([user.uid]),
            "members.\(user.uid)": ["email": user.email, "displayName": user.displayName]
        ])
    }

    func removeMember(_ uid: String, from groupId: String) async throws {
        try await groups.document(groupId).updateData([
            "memberIds": FieldValue.arrayRemove([uid]),
            "members.\(uid)": FieldValue.delete()
        ])
    }

    func deleteGroup(_ groupId: String) async throws {
        try await groups.document(groupId).delete()
    }
}
