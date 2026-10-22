import Foundation
import LocalAuthentication

// Wraps LocalAuthentication for unlocking the app with Touch ID (or Face ID on newer phones).
final class BiometricAuthService {
    enum Biometry {
        case touchID, faceID, none

        var name: String {
            switch self {
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .none: return "Passcode"
            }
        }

        var systemImage: String {
            switch self {
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .none: return "lock.fill"
            }
        }
    }

    static let shared = BiometricAuthService()

    // Face ID needs NSFaceIDUsageDescription in Info.plist; without it the request would fail.
    private var hasFaceIDUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") != nil
    }

    var biometry: Biometry {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return .none }
        switch context.biometryType {
        case .touchID: return .touchID
        case .faceID: return hasFaceIDUsageDescription ? .faceID : .none
        default: return .none
        }
    }

    var isAvailable: Bool { biometry != .none }

    // Uses the fingerprint first and lets the user fall back to the device passcode.
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw error ?? LAError(.biometryNotAvailable)
        }
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}
