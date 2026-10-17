import SwiftUI

// Guardian control to send a check-in ping and see the student's answer.
struct CheckInPanel: View {
    let studentName: String
    let latestPing: CheckInPing?
    let canSend: Bool
    let isSending: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let ping = latestPing {
                // Ticks every second so the countdown stays current without reloading the map.
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    status(for: ping, now: context.date)
                }
            }

            Button(action: onSend) {
                ZStack {
                    if isSending {
                        ProgressView()
                    } else {
                        Label("Send Check-in", systemImage: "hand.wave.fill")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSend)
            .accessibilityLabel(isSending ? "Sending check-in" : "Send Check-in")
            .accessibilityHint("Asks \(studentName) to confirm they're safe")
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    @ViewBuilder
    private func status(for ping: CheckInPing, now: Date) -> some View {
        switch ping.status {
        case .acknowledged:
            Label {
                Text("\(studentName) replied I'm Fine")
                    + Text(ping.respondedAt.map { " at \($0.formatted(date: .omitted, time: .shortened))" } ?? "")
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            }
            .font(.subheadline)
        case .missed:
            missedLabel(for: ping)
        case .pending:
            if ping.isExpired(at: now) {
                missedLabel(for: ping)
            } else {
                Label {
                    Text("Waiting for reply · ") + Text(Formatters.countdown(ping.secondsLeft(at: now))).bold()
                } icon: {
                    ProgressView()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }

    private func missedLabel(for ping: CheckInPing) -> some View {
        Label("No response to the check-in sent at \(ping.sentAt.formatted(date: .omitted, time: .shortened))",
              systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundColor(.orange)
    }
}

#Preview {
    CheckInPanel(
        studentName: "Alex",
        latestPing: CheckInPing(tripId: "t1", studentId: "alex", studentName: "Alex Perera",
                                senderId: "maya", senderName: "Maya Perera", memberIds: ["alex", "maya"],
                                sentAt: Date(), deadline: Date().addingTimeInterval(45), status: .pending),
        canSend: false,
        isSending: false,
        onSend: {}
    )
    .padding()
}
