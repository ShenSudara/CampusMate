import Foundation
import FirebaseAuth

enum AppError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }

    // Turns Firebase and system errors into text a user can understand.
    static func userMessage(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "Something went wrong."
        }
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidEmail: return "That email address is not valid."
            case .emailAlreadyInUse: return "An account with this email already exists."
            case .weakPassword: return "Please choose a stronger password (at least 6 characters)."
            case .wrongPassword, .invalidCredential, .userNotFound: return "Incorrect email or password."
            case .userDisabled: return "This account has been disabled."
            case .tooManyRequests: return "Too many attempts. Please wait a moment and try again."
            case .networkError: return "No internet connection. Check your network and try again."
            default: break
            }
        }
        if nsError.domain == NSURLErrorDomain {
            return "No internet connection. Check your network and try again."
        }
        return nsError.localizedDescription
    }
}
