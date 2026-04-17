import SwiftUI

// authentication application flow
struct AuthRootView: View {
    let flow: AuthFlow

    var body: some View {
        NavigationStack {
            switch flow {
            case .signIn:
                SignInView()
            case .signUp:
                SignUpView()
            case .setupProfile:
                SetupProfileView()
            case .passwordReset:
                PasswordResetView()
            case .passwordResetConfirmed:
                PasswordResetConfirmedView()
            }
        }
    }
}
