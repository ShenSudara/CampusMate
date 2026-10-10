import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var user: AppUser?
    @Published private(set) var isLoading = true
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let userService: UserService
    private let authService: AuthService
    private var listener: ListenerRegistration?

    init(userService: UserService = .shared, authService: AuthService = .shared) {
        self.userService = userService
        self.authService = authService
    }

    var mode: UserMode { user?.activeMode ?? .student }
    var userId: String? { authService.currentUserId }

    func start() async {
        guard listener == nil, let uid = authService.currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.ensureProfile(
                uid: uid,
                email: authService.currentUserEmail ?? "",
                displayName: authService.currentDisplayName ?? ""
            )
        } catch {
            errorMessage = AppError.userMessage(for: error)
            isLoading = false
            return
        }
        listener = userService.listenToUser(uid: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let user):
                    self.user = user
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
        user = nil
        isLoading = true
    }

    func retry() async {
        stop()
        await start()
    }

    func switchMode(to mode: UserMode) async {
        guard let uid = user?.id, mode != user?.activeMode else { return }
        await save { try await self.userService.updateMode(uid: uid, mode: mode) }
    }

    func updateDisplayName(_ name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let uid = user?.id, InputValidator.isValidName(trimmed) else {
            errorMessage = "Name cannot be empty."
            return
        }
        await save { try await self.userService.updateDisplayName(uid: uid, name: trimmed) }
    }

    private func save(_ action: @escaping () async throws -> Void) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await action()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }
}
