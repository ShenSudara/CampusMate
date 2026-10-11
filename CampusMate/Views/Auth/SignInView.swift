import SwiftUI

struct SignInView: View {
    @Binding var email: String
    @Binding var password: String
    let isLoading: Bool
    let errorMessage: String?
    let onSignIn: () -> Void
    let onShowSignUp: () -> Void

    private var canSubmit: Bool {
        InputValidator.isValidEmail(email) && InputValidator.isValidPassword(password) && !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.accentColor)
                    Text("CampusMate")
                        .font(.largeTitle.bold())
                    Text("Travel safely. Stay connected.")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 48)

                VStack(spacing: 12) {
                    AuthTextField(title: "Email", systemImage: "envelope", text: $email,
                                  keyboardType: .emailAddress, contentType: .emailAddress)
                    AuthTextField(title: "Password", systemImage: "lock", text: $password,
                                  isSecure: true, contentType: .password)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: onSignIn) {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!canSubmit)

                Button("Don't have an account? Sign Up", action: onShowSignUp)
                    .font(.footnote)
                    .disabled(isLoading)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

#Preview {
    SignInView(email: .constant(""), password: .constant(""), isLoading: false,
               errorMessage: nil, onSignIn: {}, onShowSignUp: {})
}
