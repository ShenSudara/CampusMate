import SwiftUI

struct PrimaryTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .regular))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
    }
}

struct FieldErrorText: View {
    let message: String?

    var body: some View {
        Group {
            if let message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TextField("Test Field", text: .constant("Test Text"))
            .textFieldStyle(PrimaryTextFieldStyle())
        
        FieldErrorText(message: "test error messages")

        
    }
    .padding()
}
