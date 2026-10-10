import Foundation
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()

    private let auth = Auth.auth()

    var currentUserId: String? { auth.currentUser?.uid }
    var currentUserEmail: String? { auth.currentUser?.email }

    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in handler(user) }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await auth.signIn(withEmail: email, password: password)
    }

    func signUp(displayName: String, email: String, password: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        let request = result.user.createProfileChangeRequest()
        request.displayName = displayName
        try await request.commitChanges()
        return result.user
    }

    func signOut() throws {
        try auth.signOut()
    }
}
