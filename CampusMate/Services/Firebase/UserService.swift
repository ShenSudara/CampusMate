import Foundation
import FirebaseFirestore

final class UserService {
    static let shared = UserService()

    private lazy var users = Firestore.firestore().collection("users")

    // Creates the profile on first sign-in, so older accounts get one too.
    func ensureProfile(uid: String, email: String, displayName: String) async throws {
        let ref = users.document(uid)
        let snapshot = try await ref.getDocument()
        if snapshot.exists { return }
        let user = AppUser(
            email: email.lowercased(),
            displayName: displayName.isEmpty ? email : displayName,
            activeMode: .student,
            createdAt: Date()
        )
        try ref.setData(from: user)
    }

    func listenToUser(uid: String,
                      onChange: @escaping (Result<AppUser, Error>) -> Void) -> ListenerRegistration {
        users.document(uid).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists else { return }
            do {
                onChange(.success(try snapshot.data(as: AppUser.self)))
            } catch {
                onChange(.failure(error))
            }
        }
    }

    func findUser(byEmail email: String) async throws -> AppUser? {
        let snapshot = try await users
            .whereField("email", isEqualTo: email.lowercased())
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first?.data(as: AppUser.self)
    }

    func updateMode(uid: String, mode: UserMode) async throws {
        try await users.document(uid).updateData(["activeMode": mode.rawValue])
    }

    func updateDisplayName(uid: String, name: String) async throws {
        try await users.document(uid).updateData(["displayName": name])
    }

    func updateSelectedStudent(uid: String, studentId: String?) async throws {
        try await users.document(uid).updateData(["selectedStudentId": studentId ?? FieldValue.delete()])
    }
}
