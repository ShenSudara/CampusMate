import Foundation

// data model for sign in
struct SignInModel {
    var email: String = ""
    var password: String = ""
}

// validation for sign in
enum SignInValidation {
    static func emailError(for email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Email is required." }

        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let isValid = NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed)
        return isValid ? nil : "Enter a valid email address."
    }

    static func passwordError(for password: String) -> String? {
        guard !password.isEmpty else { return "Password is required." }
        guard password.count >= 6 else { return "Password must be at least 6 characters." }
        return nil
    }
}
