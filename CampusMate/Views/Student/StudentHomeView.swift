import SwiftUI

struct StudentHomeView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var viewModel: StudentHomeViewModel
    @ObservedObject var tripViewModel: TripViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    let onOpenDestination: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, \(session.user?.displayName ?? "there")")
                        .font(.title2.bold())
                    Text(tripViewModel.activeTrip == nil
                         ? "Set where you're heading before you leave."
                         : "Your group can follow your journey.")
                        .foregroundColor(.secondary)
                }

                if tripViewModel.isLocationDenied || tripViewModel.needsLocationPermission {
                    LocationPermissionBanner(isDenied: tripViewModel.isLocationDenied,
                                             onAllow: tripViewModel.requestLocationPermission)
                }

                if tripViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let trip = tripViewModel.activeTrip {
                    ActiveTripCard(trip: trip, isWorking: tripViewModel.isWorking) {
                        Task { await tripViewModel.endTrip() }
                    }
                } else {
                    destinationSection
                    startButton
                }

                if let errorMessage = tripViewModel.errorMessage {
                    Text(errorMessage)
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
                onChange: onOpenDestination,
                onClear: viewModel.clearDestination
            )
        } else {
            Button(action: onOpenDestination) {
                HStack(spacing: 14) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
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
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }

    private var startButton: some View {
        Button {
            Task {
                await tripViewModel.startTrip(student: session.user,
                                              groups: groupsViewModel.groups,
                                              destination: viewModel.destination)
            }
        } label: {
            ZStack {
                if tripViewModel.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Label("Start Journey", systemImage: "figure.walk.departure")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(viewModel.destination == nil ? Color.gray.opacity(0.4) : Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(14)
        .disabled(viewModel.destination == nil || tripViewModel.isWorking)
    }
}

#Preview {
    NavigationStack {
        StudentHomeView(session: SessionViewModel(),
                        viewModel: StudentHomeViewModel(),
                        tripViewModel: TripViewModel(),
                        groupsViewModel: GroupsViewModel(),
                        onOpenDestination: {})
            .navigationTitle("Student")
    }
}
