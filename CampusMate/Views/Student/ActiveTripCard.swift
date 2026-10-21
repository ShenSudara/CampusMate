import SwiftUI
import CoreLocation

struct ActiveTripCard: View {
    let trip: Trip
    let userCoordinate: CLLocationCoordinate2D?
    var lastSharedAt: Date?
    var sharingError: String?
    let isWorking: Bool
    let onEnd: () -> Void
    @State private var confirmEnd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RouteMapPreview(destination: trip.destination,
                            userCoordinate: userCoordinate ?? trip.lastCoordinate)
                .accessibilityElement()
                .accessibilityLabel("Map showing your location and \(trip.destination.name)")
            details
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .confirmationDialog("Cancel this journey?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("Cancel Journey", role: .destructive, action: onEnd)
            Button("Keep Sharing", role: .cancel) {}
        } message: {
            Text("Location sharing will stop and your group will see the journey as finished.")
        }
    }

    private var sharedWithText: String {
        let count = max(trip.memberIds.count - 1, 0)
        return count == 1 ? "1 member" : "\(count) members"
    }

    private var details: some View {
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

            SharingStatusView(lastSharedAt: lastSharedAt, errorMessage: sharingError)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination.name)
                        .font(.subheadline.bold())
                    if !trip.destination.address.isEmpty {
                        Text(trip.destination.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    DestinationWeatherView(destination: trip.destination)
                        .padding(.top, 2)
                }
            }

            Text("Started at \(trip.startedAt.formatted(date: .omitted, time: .shortened)) · shared with \(sharedWithText)")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(role: .destructive) {
                confirmEnd = true
            } label: {
                ZStack {
                    if isWorking {
                        ProgressView()
                    } else {
                        Text("Cancel Journey").bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(isWorking)
        }
        .padding()
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
        userCoordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        lastSharedAt: Date().addingTimeInterval(-8),
        isWorking: false,
        onEnd: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
