import Foundation
import Combine

// sign in view model
final class SignInViewModel: ObservableObject {
    @Published var model = SignInModel()
    @Published var emailError: String?
    @Published var passwordError: String?
    
// methods for signIn
    var trySignIn: Bool{
        return true
    }
    
// validation methods for signIn
    var signInEnabled: Bool {
        !model.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.password.isEmpty
    }

    var isFormValid: Bool {
        SignInValidation.emailError(for: model.email) == nil &&
        SignInValidation.passwordError(for: model.password) == nil
    }

    func validateEmail() {
        emailError = SignInValidation.emailError(for: model.email)
    }

    func validatePassword() {
        passwordError = SignInValidation.passwordError(for: model.password)
    }

    func validateAll() {
        validateEmail()
        validatePassword()
    }

    func clearErrorsAsUserTypes() {
        if emailError != nil {
            validateEmail()
        }

        if passwordError != nil {
            validatePassword()
        }
    }
}
