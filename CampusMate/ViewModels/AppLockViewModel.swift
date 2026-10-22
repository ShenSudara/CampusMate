import Foundation
import Combine
import LocalAuthentication

// Locks the app behind Touch ID when the user turns it on in Profile.
@MainActor
final class AppLockViewModel: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var isLocked: Bool
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    private let authService: BiometricAuthService
    private let enabledKey = "appLockEnabled"

    init(authService: BiometricAuthService = .shared) {
        self.authService = authService
        let enabled = UserDefaults.standard.bool(forKey: enabledKey)
        isEnabled = enabled
        // Locked at launch so the app opens behind Touch ID.
        isLocked = enabled
    }

    var biometry: BiometricAuthService.Biometry { authService.biometry }
    var isAvailable: Bool { authService.isAvailable }

    // Turning the lock on needs one successful unlock, so the user knows it works.
    func setEnabled(_ enabled: Bool) async {
        errorMessage = nil
        guard enabled else {
            save(false)
            return
        }
        guard isAvailable else {
            errorMessage = "Touch ID isn't set up on this phone. Add a fingerprint in Settings → Touch ID & Passcode."
            return
        }
        if await authenticate(reason: "Turn on Touch ID for CampusMate") {
            save(true)
        }
    }

    // While a journey is active the app stays open, so SOS and journey controls are always one tap away.
    func lockIfNeeded(hasActiveJourney: Bool) {
        guard isEnabled, !hasActiveJourney else { return }
        isLocked = true
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        if await authenticate(reason: "Unlock CampusMate") {
            isLocked = false
        }
    }

    // Signing out clears the lock so the sign-in screen is never hidden.
    func reset() {
        isLocked = false
        isAuthenticating = false
        errorMessage = nil
    }

    private func authenticate(reason: String) async -> Bool {
        isAuthenticating = true
        errorMessage = nil
        defer { isAuthenticating = false }
        do {
            return try await authService.authenticate(reason: reason)
        } catch let error as LAError where error.code == .userCancel || error.code == .appCancel || error.code == .systemCancel {
            return false
        } catch {
            errorMessage = "Couldn't confirm it's you. Please try again."
            return false
        }
    }

    private func save(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        if !enabled { isLocked = false }
    }
}
