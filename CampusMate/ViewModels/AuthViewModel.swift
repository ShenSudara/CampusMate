import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    enum Screen {
        case signIn, signUp
    }

    @Published var screen: Screen = .signIn
    @Published var displayName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var userId: String?
    @Published private(set) var hasCheckedSession = false

    private let authService: AuthService
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    var isSignedIn: Bool { userId != nil }

    init(authService: AuthService = .shared) {
        self.authService = authService
        listenerHandle = authService.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.userId = user?.uid
                self?.hasCheckedSession = true
            }
        }
    }

    deinit {
        if let listenerHandle {
            AuthService.shared.removeAuthStateListener(listenerHandle)
        }
    }

    func showSignUp() {
        errorMessage = nil
        screen = .signUp
    }

    func showSignIn() {
        errorMessage = nil
        screen = .signIn
    }

    func signIn() async {
        await perform {
            try await self.authService.signIn(email: self.trimmedEmail, password: self.password)
        }
    }

    func signUp() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        await perform {
            let name = self.displayName.trimmingCharacters(in: .whitespaces)
            _ = try await self.authService.signUp(displayName: name, email: self.trimmedEmail, password: self.password)
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            clearForm()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private func perform(_ action: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
            clearForm()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    private func clearForm() {
        password = ""
        confirmPassword = ""
    }
}
