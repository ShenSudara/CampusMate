import Foundation
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()

    private let auth = Auth.auth()

    var currentUserId: String? { auth.currentUser?.uid }
    var currentUserEmail: String? { auth.currentUser?.email }
    var currentDisplayName: String? { auth.currentUser?.displayName }

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
        try await result.user.sendEmailVerification()
        return result.user
    }

    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else { throw AppError.message("You are not signed in.") }
        try await user.sendEmailVerification()
    }

    // Fetches the latest account state so a link clicked in the email is picked up.
    func reloadIsEmailVerified() async throws -> Bool {
        guard let user = auth.currentUser else { throw AppError.message("You are not signed in.") }
        try await user.reload()
        return auth.currentUser?.isEmailVerified ?? false
    }

    func signOut() throws {
        try auth.signOut()
    }
}
