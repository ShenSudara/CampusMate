import Foundation
import FirebaseAuth
import FirebaseCore

final class AuthService {
    static let shared = AuthService()

    private lazy var auth = Auth.auth()

    // False in SwiftUI previews, where the app delegate does not run.
    private var isFirebaseReady: Bool { FirebaseApp.app() != nil }

    var currentUserId: String? { isFirebaseReady ? auth.currentUser?.uid : nil }
    var currentUserEmail: String? { isFirebaseReady ? auth.currentUser?.email : nil }
    var currentDisplayName: String? { isFirebaseReady ? auth.currentUser?.displayName : nil }

    func addAuthStateListener(_ handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        guard isFirebaseReady else { return nil }
        return auth.addStateDidChangeListener { _, user in handler(user) }
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
