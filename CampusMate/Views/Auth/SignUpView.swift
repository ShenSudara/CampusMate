import SwiftUI

struct SignUpView: View {
    @Binding var displayName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    let isLoading: Bool
    let errorMessage: String?
    let onSignUp: () -> Void
    let onShowSignIn: () -> Void

    private var passwordsMatch: Bool { password == confirmPassword }

    private var canSubmit: Bool {
        InputValidator.isValidName(displayName)
            && InputValidator.isValidEmail(email)
            && InputValidator.isValidPassword(password)
            && passwordsMatch
            && !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                    Text("Join CampusMate to share your journeys with people you trust.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)

                VStack(spacing: 12) {
                    AuthTextField(title: "Full name", systemImage: "person", text: $displayName,
                                  contentType: .name)
                    AuthTextField(title: "Email", systemImage: "envelope", text: $email,
                                  keyboardType: .emailAddress, contentType: .emailAddress)
                    AuthTextField(title: "Password (min \(InputValidator.minimumPasswordLength) characters)",
                                  systemImage: "lock", text: $password,
                                  isSecure: true, contentType: .newPassword)
                    AuthTextField(title: "Confirm password", systemImage: "lock.rotation",
                                  text: $confirmPassword, isSecure: true, contentType: .newPassword)
                }

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: onSignUp) {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign Up").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!canSubmit)

                Button("Already have an account? Sign In", action: onShowSignIn)
                    .font(.footnote)
                    .disabled(isLoading)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
