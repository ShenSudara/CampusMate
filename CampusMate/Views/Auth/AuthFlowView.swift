import SwiftUI

struct AuthFlowView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        switch viewModel.screen {
        case .signIn:
            SignInView(
                email: $viewModel.email,
                password: $viewModel.password,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                onSignIn: { Task { await viewModel.signIn() } },
                onShowSignUp: viewModel.showSignUp
            )
        case .signUp:
            SignUpView(
                displayName: $viewModel.displayName,
                email: $viewModel.email,
                password: $viewModel.password,
                confirmPassword: $viewModel.confirmPassword,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                onSignUp: { Task { await viewModel.signUp() } },
                onShowSignIn: viewModel.showSignIn
            )
        }
    }
}

#Preview {
    AuthFlowView(viewModel: AuthViewModel())
}
