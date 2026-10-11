import SwiftUI

struct AuthTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                        .autocorrectionDisabled()
                }
            }
            .textContentType(contentType)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    AuthTextField(title: "Email", systemImage: "envelope", text: .constant(""),
                  keyboardType: .emailAddress, contentType: .emailAddress)
        .padding()
}
