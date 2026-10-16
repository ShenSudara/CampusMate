import SwiftUI

struct CheckInPromptView: View {
    let senderName: String
    let secondsLeft: Int
    let progress: Double
    let isExpired: Bool
    let isResponding: Bool
    let errorMessage: String?
    let onImFine: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "hand.wave.fill")
                    .font(.system(size: 52))
                    .foregroundColor(isExpired ? .orange : .accentColor)
                Text(isExpired ? "Time's up" : "Are you OK?")
                    .font(.largeTitle.bold())
                Text(isExpired
                     ? "\(senderName) will see that you didn't respond in time. Tap I'm Fine to let them know you're safe."
                     : "\(senderName) sent you a check-in. Let them know you're safe.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isExpired ? Color.orange : Color.accentColor,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                Text(Formatters.countdown(secondsLeft))
                    .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
            }
            .frame(width: 180, height: 180)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(secondsLeft) seconds left")

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: onImFine) {
                ZStack {
                    if isResponding {
                        ProgressView().tint(.white)
                    } else {
                        Label("I'm Fine", systemImage: "checkmark.circle.fill")
                            .font(.title2.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .background(Color.confirmGreen)
            .foregroundColor(.white)
            .cornerRadius(18)
            .disabled(isResponding)

            if isExpired {
                Button("Close", action: onDismiss)
                    .disabled(isResponding)
            }
        }
        .padding(24)
        .background(Color(.systemBackground).ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}

#Preview {
    CheckInPromptView(senderName: "Maya Perera", secondsLeft: 245, progress: 0.8, isExpired: false,
                      isResponding: false, errorMessage: nil, onImFine: {}, onDismiss: {})
}
