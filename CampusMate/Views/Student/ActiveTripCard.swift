import SwiftUI

struct ActiveTripCard: View {
    let trip: Trip
    let isWorking: Bool
    let onEnd: () -> Void
    @State private var confirmEnd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Journey in progress", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text(trip.startedAt, style: .timer)
                    .font(.headline.monospacedDigit())
                    .accessibilityLabel("Elapsed time")
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination.name)
                        .font(.subheadline.bold())
                    if !trip.destination.address.isEmpty {
                        Text(trip.destination.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("Started at \(trip.startedAt.formatted(date: .omitted, time: .shortened)) · shared with \(max(trip.memberIds.count - 1, 0)) member(s)")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(role: .destructive) {
                confirmEnd = true
            } label: {
                ZStack {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text("End Journey").bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(isWorking)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .confirmationDialog("End this journey?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End Journey", role: .destructive, action: onEnd)
        } message: {
            Text("Your guardians will see that you have arrived and location sharing will stop.")
        }
    }
}

#Preview {
    ActiveTripCard(
        trip: Trip(
            studentId: "alex",
            studentName: "Alex Perera",
            groupIds: ["family"],
            memberIds: ["alex", "maya"],
            status: .active,
            destination: Destination(name: "NIBM Colombo", address: "Wijerama Mawatha, Colombo 07",
                                     latitude: 6.9063, longitude: 79.8706),
            startedAt: Date().addingTimeInterval(-600)
        ),
        isWorking: false,
        onEnd: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
