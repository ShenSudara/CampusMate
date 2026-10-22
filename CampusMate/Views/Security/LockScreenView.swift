import SwiftUI

struct LockScreenView: View {
    let biometryName: String
    let systemImage: String
    let isAuthenticating: Bool
    let errorMessage: String?
    let onUnlock: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("CampusMate is locked")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Use \(biometryName) to continue.")
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onUnlock) {
                ZStack {
                    if isAuthenticating {
                        ProgressView().tint(.white)
                    } else {
                        Label("Unlock with \(biometryName)", systemImage: systemImage)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isAuthenticating)

            Button("Sign Out", role: .destructive, action: onSignOut)
                .font(.footnote)
                .disabled(isAuthenticating)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

#Preview {
    LockScreenView(biometryName: "Touch ID", systemImage: "touchid", isAuthenticating: false,
                   errorMessage: nil, onUnlock: {}, onSignOut: {})
}
