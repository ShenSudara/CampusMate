import SwiftUI

struct SignedInView: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                Text("You're signed in")
                    .font(.title2.bold())
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                Button("Sign Out", role: .destructive, action: authViewModel.signOut)
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("CampusMate")
        }
    }
}
