import SwiftUI

struct AlertRowView: View {
    let alert: SafetyAlert
    var isUnseen = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.type.systemImage)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(alert.type.isCritical ? Color.red : Color.orange)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(alert.type.title)
                        .font(.headline)
                    if isUnseen {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .accessibilityLabel("New")
                    }
                }
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(alert.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(" ago · \(alert.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        AlertRowView(alert: SafetyAlert(type: .missedCheckIn, studentId: "alex", studentName: "Alex Perera",
                                        tripId: "t1", memberIds: ["alex", "maya"],
                                        message: "Alex Perera didn't respond to Maya Perera's check-in.",
                                        createdAt: Date().addingTimeInterval(-300), createdBy: "maya"),
                     isUnseen: true)
    }
}
