import SwiftUI
import MapKit

struct DestinationMapView: View {
    @ObservedObject var viewModel: StudentHomeViewModel
    @ObservedObject var tripViewModel: TripViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    @ObservedObject var session: SessionViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var confirmCancel = false

    private var activeTrip: Trip? { tripViewModel.activeTrip }

    private var mapDestination: Destination? { activeTrip?.destination ?? viewModel.destination }

    private var showsSuggestions: Bool {
        activeTrip == nil && isSearchFocused && !viewModel.searchText.isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $viewModel.mapRegion,
                showsUserLocation: true,
                annotationItems: mapDestination.map { [$0] } ?? []) { place in
                MapMarker(coordinate: place.coordinate, tint: .red)
            }
            .ignoresSafeArea(edges: .top)
            .onTapGesture { isSearchFocused = false }

            VStack(spacing: 8) {
                if activeTrip == nil {
                    searchBar
                } else {
                    tripBanner
                }

                if tripViewModel.isLocationDenied || tripViewModel.needsLocationPermission {
                    LocationPermissionBanner(isDenied: tripViewModel.isLocationDenied,
                                             onAllow: tripViewModel.requestLocationPermission)
                }

                if let errorMessage = viewModel.errorMessage ?? tripViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }

                if showsSuggestions {
                    suggestionList
                }

                Spacer()

                HStack {
                    Spacer()
                    if viewModel.userCoordinate != nil {
                        Button(action: viewModel.centerOnUser) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .padding(12)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Show my location")
                    }
                }

                if !showsSuggestions {
                    if let trip = activeTrip {
                        activeTripPanel(for: trip)
                    } else if let destination = viewModel.destination {
                        selectedPanel(for: destination)
                    }
                }
            }
            .padding()

            if viewModel.isResolving {
                ProgressView("Finding place…")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    .frame(maxHeight: .infinity)
            }
        }
        .onChange(of: activeTrip?.id) { _ in
            if let trip = activeTrip {
                viewModel.showRoute(to: trip.destination)
            }
        }
        .confirmationDialog("Cancel this journey?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("Cancel Journey", role: .destructive) {
                Task { await tripViewModel.endTrip() }
            }
            Button("Keep Sharing", role: .cancel) {}
        } message: {
            Text("Location sharing will stop and your group will see the journey as finished.")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Where are you going?", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    private var tripBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("Journey in progress", systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
                Spacer()
                if let trip = activeTrip {
                    Text(trip.startedAt, style: .timer)
                        .font(.subheadline.monospacedDigit())
                }
            }
            SharingStatusView(lastSharedAt: tripViewModel.lastSharedAt,
                              errorMessage: tripViewModel.sharingError)
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private var suggestionList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if viewModel.suggestions.isEmpty {
                    Text("No places found for \"\(viewModel.searchText)\".")
                        .foregroundColor(.secondary)
                        .padding()
                }
                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        isSearchFocused = false
                        Task {
                            if await viewModel.select(suggestion), let destination = viewModel.destination {
                                viewModel.showRoute(to: destination)
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .foregroundColor(.primary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .disabled(viewModel.isResolving)
                    Divider().padding(.leading, 52)
                }
            }
        }
        .frame(maxHeight: 320)
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func destinationRow(for destination: Destination, removable: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(.headline)
                if !destination.address.isEmpty {
                    Text(destination.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if removable {
                Button(action: viewModel.clearDestination) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Remove destination")
            }
        }
    }

    private func selectedPanel(for destination: Destination) -> some View {
        VStack(spacing: 14) {
            destinationRow(for: destination, removable: true)
            Button {
                Task {
                    await tripViewModel.startTrip(student: session.user,
                                                  groups: groupsViewModel.groups,
                                                  destination: destination)
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
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(14)
            .disabled(tripViewModel.isWorking)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    private func activeTripPanel(for trip: Trip) -> some View {
        VStack(spacing: 14) {
            destinationRow(for: trip.destination, removable: false)
            Button(role: .destructive) {
                confirmCancel = true
            } label: {
                ZStack {
                    if tripViewModel.isWorking {
                        ProgressView()
                    } else {
                        Label("Cancel Journey", systemImage: "xmark.octagon")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(tripViewModel.isWorking)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }
}

#Preview {
    DestinationMapView(viewModel: StudentHomeViewModel(),
                       tripViewModel: TripViewModel(),
                       groupsViewModel: GroupsViewModel(),
                       session: SessionViewModel())
}
