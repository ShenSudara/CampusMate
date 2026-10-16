import SwiftUI

struct AreYouOKView: View {
    let reason: String
    let secondsLeft: Int
    let progress: Double
    let isSending: Bool
    let alertSent: Bool
    let errorMessage: String?
    let onImOK: () -> Void
    let onSendNow: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: alertSent ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(alertSent ? .green : .red)
                Text(alertSent ? "Your group has been alerted" : "Are you OK?")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(alertSent
                     ? "Your guardians can see your location. Stay where you are if it's safe."
                     : "\(reason) If you don't respond, your group will be alerted with your location.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            if !alertSent {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    if isSending {
                        ProgressView()
                    } else {
                        Text("\(secondsLeft)")
                            .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    }
                }
                .frame(width: 180, height: 180)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(isSending ? "Sending alert" : "\(secondsLeft) seconds left")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if alertSent {
                Button(action: onClose) {
                    Text("Close").bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: onImOK) {
                    Label("I'm OK", systemImage: "checkmark.circle.fill")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
                .background(Color.confirmGreen)
                .foregroundColor(.white)
                .cornerRadius(18)
                .disabled(isSending)

                Button(role: .destructive, action: onSendNow) {
                    Label(errorMessage == nil ? "Send Alert Now" : "Try Again", systemImage: "exclamationmark.bubble.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .disabled(isSending)
            }
        }
        .padding(24)
        .background(Color(.systemBackground).ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}

#Preview {
    AreYouOKView(reason: "We detected a hard impact.", secondsLeft: 24, progress: 0.8, isSending: false,
                 alertSent: false, errorMessage: nil, onImOK: {}, onSendNow: {}, onClose: {})
}
