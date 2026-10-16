import SwiftUI

struct VerifyEmailView: View {
    @ObservedObject var viewModel: AuthViewModel
    let email: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                    .padding(.top, 48)
                Text("Verify your email")
                    .font(.title.bold())
                Text("We sent a verification link to \(email). Open it, then come back and tap \"I've Verified\".")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if let infoMessage = viewModel.infoMessage {
                    Label {
                        Text(infoMessage)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.checkEmailVerified() }
                } label: {
                    ZStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("I've Verified").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isLoading)

                Button("Resend Email") {
                    Task { await viewModel.resendVerificationEmail() }
                }
                .disabled(viewModel.isLoading)

                Button("Sign Out", role: .destructive, action: viewModel.signOut)
                    .font(.footnote)
                    .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

#Preview {
    VerifyEmailView(viewModel: AuthViewModel(), email: "alex@example.com")
}
