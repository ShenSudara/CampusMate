import SwiftUI

// Red SOS button that must be held, so a pocket tap can't send it.
struct SOSButton: View {
    let isSending: Bool
    let lastSentAt: Date?
    let secondsUntilAvailable: Int
    let errorMessage: String?
    let onSend: () -> Void

    @State private var isPressing = false

    private var isDisabled: Bool { isSending || secondsUntilAvailable > 0 }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(isDisabled ? 0.45 : 1))
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: isPressing ? proxy.size.width : 0)
                        .animation(isPressing ? .linear(duration: SafetyThresholds.sosHoldDuration) : .easeOut(duration: 0.2),
                                   value: isPressing)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                if isSending {
                    ProgressView().tint(.white)
                } else {
                    Label(isPressing ? "Keep holding…" : "Hold for SOS", systemImage: "sos")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 54)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: SafetyThresholds.sosHoldDuration,
                                perform: {
                                    isPressing = false
                                    onSend()
                                },
                                onPressingChanged: { pressing in
                                    isPressing = pressing && !isDisabled
                                })
            .disabled(isDisabled)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("SOS")
            .accessibilityHint("Sends an emergency alert with your location to your group.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onSend() }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let lastSentAt {
                Text(secondsUntilAvailable > 0
                     ? "SOS sent at \(lastSentAt.formatted(date: .omitted, time: .shortened)). You can send again in \(secondsUntilAvailable)s."
                     : "SOS sent at \(lastSentAt.formatted(date: .omitted, time: .shortened)). Your group has been alerted.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SOSButton(isSending: false, lastSentAt: nil, secondsUntilAvailable: 0, errorMessage: nil, onSend: {})
        SOSButton(isSending: false, lastSentAt: Date(), secondsUntilAvailable: 18, errorMessage: nil, onSend: {})
    }
    .padding()
}
