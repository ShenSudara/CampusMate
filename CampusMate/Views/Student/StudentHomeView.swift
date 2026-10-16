import SwiftUI

struct StudentHomeView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var viewModel: StudentHomeViewModel
    @ObservedObject var tripViewModel: TripViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    @ObservedObject var sosViewModel: SOSViewModel
    let onOpenDestination: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, \(session.user?.displayName ?? "there")")
                        .font(.title2.bold())
                    Text(tripViewModel.activeTrip == nil
                         ? "Pick your destination and start your journey from the Destination tab."
                         : "Your group can follow your journey.")
                        .foregroundColor(.secondary)
                }

                if tripViewModel.isLocationDenied || tripViewModel.needsLocationPermission {
                    LocationPermissionBanner(isDenied: tripViewModel.isLocationDenied,
                                             onAllow: tripViewModel.requestLocationPermission)
                }

                if tripViewModel.isLoading {
                    ProgressView("Checking for an active journey…")
                        .frame(maxWidth: .infinity)
                } else if let trip = tripViewModel.activeTrip {
                    if !tripViewModel.hasAlwaysPermission && !tripViewModel.isLocationDenied {
                        backgroundSharingNotice
                    }
                    sosButton(for: trip)
                    ActiveTripCard(trip: trip,
                                   userCoordinate: viewModel.userCoordinate,
                                   lastSharedAt: tripViewModel.lastSharedAt,
                                   sharingError: tripViewModel.sharingError,
                                   isWorking: tripViewModel.isWorking) {
                        Task { await tripViewModel.endTrip() }
                    }
                } else {
                    destinationSection
                }

                if let errorMessage = tripViewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private var destinationSection: some View {
        if let destination = viewModel.destination {
            DestinationCard(
                destination: destination,
                userCoordinate: viewModel.userCoordinate,
                onChange: onOpenDestination,
                onClear: viewModel.clearDestination
            )
        } else {
            Button(action: onOpenDestination) {
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set Destination")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Search for where you're travelling to")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the Destination tab")
        }
    }

    // Without "Always" access, sharing pauses when the phone is locked or the app is closed.
    private var backgroundSharingNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sharing stops when your phone is locked", systemImage: "lock.trianglebadge.exclamationmark")
                .font(.subheadline.bold())
                .foregroundColor(.orange)
            Text("Set CampusMate's location access to \"Always\" so your group can still follow you with the screen off.")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func sosButton(for trip: Trip) -> some View {
        SOSButton(isSending: sosViewModel.isSending,
                  lastSentAt: sosViewModel.lastSentAt,
                  secondsUntilAvailable: sosViewModel.secondsUntilAvailable,
                  errorMessage: sosViewModel.errorMessage,
                  onSend: { Task { await sosViewModel.send(for: trip) } })
    }
}

#Preview {
    NavigationStack {
        StudentHomeView(session: SessionViewModel(),
                        viewModel: StudentHomeViewModel(),
                        tripViewModel: TripViewModel(),
                        groupsViewModel: GroupsViewModel(),
                        sosViewModel: SOSViewModel(),
                        onOpenDestination: {})
            .navigationTitle("Student")
    }
}
