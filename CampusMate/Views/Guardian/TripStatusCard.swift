import SwiftUI

struct TripStatusCard: View {
    let student: WatchedStudent
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.displayName)
                        .font(.headline)
                    if !student.groupNames.isEmpty {
                        Text(student.groupNames.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                statusBadge
            }
            .accessibilityElement(children: .combine)

            if let trip = student.activeTrip {
                Divider()
                Label {
                    Text(trip.destination.name).font(.subheadline.bold())
                } icon: {
                    Image(systemName: "flag.checkered").foregroundColor(.red)
                }
                .accessibilityLabel("Heading to \(trip.destination.name)")
                HStack(spacing: 16) {
                    Label(trip.startedAt.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .accessibilityLabel("Started at \(trip.startedAt.formatted(date: .omitted, time: .shortened))")
                    // GPS reports small speeds while standing still, so show those as stopped.
                    if let speed = trip.lastSpeed {
                        if speed < 0.5 {
                            Label("Stopped", systemImage: "pause.circle")
                        } else {
                            Label(String(format: "%.0f km/h", speed * 3.6), systemImage: "speedometer")
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let lastLocationAt = trip.lastLocationAt {
                    Label {
                        Text("Updated ") + Text(lastLocationAt, style: .relative) + Text(" ago")
                    } icon: {
                        Image(systemName: isStale ? "exclamationmark.triangle.fill" : "location.fill")
                    }
                    .font(.caption)
                    .foregroundColor(isStale ? .orange : .secondary)
                } else {
                    Label("Waiting for the first location update", systemImage: "location.magnifyingglass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isStale {
                    Text("No location received for a while. Their phone may be offline, out of battery or have location turned off.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else {
                Text("Not on a journey right now. You'll see their live location here when they start one.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if student.activeTrip == nil {
            badge("Not travelling", systemImage: "moon.zzz", color: .secondary)
        } else if isStale {
            badge("Signal lost", systemImage: "antenna.radiowaves.left.and.right.slash", color: .orange)
        } else {
            badge("Live", systemImage: "dot.radiowaves.left.and.right", color: .green)
        }
    }

    private func badge(_ title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    TripStatusCard(
        student: WatchedStudent(
            id: "alex",
            displayName: "Alex Perera",
            email: "alex@example.com",
            groupNames: ["Family"],
            activeTrip: Trip(
                studentId: "alex",
                studentName: "Alex Perera",
                groupIds: ["family"],
                memberIds: ["alex", "maya"],
                status: .active,
                destination: Destination(name: "NIBM Colombo", address: "Colombo 07",
                                         latitude: 6.9063, longitude: 79.8706),
                startedAt: Date().addingTimeInterval(-900),
                lastLatitude: 6.92,
                lastLongitude: 79.865,
                lastLocationAt: Date().addingTimeInterval(-20),
                lastSpeed: 1.4
            )
        ),
        isStale: false
    )
    .padding()
}
