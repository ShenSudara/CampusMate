import Foundation
import Combine
import MapKit

@MainActor
final class StudentHomeViewModel: ObservableObject {
    @Published var searchText = "" {
        didSet { searchService.updateQuery(searchText) }
    }
    @Published private(set) var suggestions: [PlaceSuggestion] = []
    @Published private(set) var destination: Destination?
    @Published private(set) var isResolving = false
    @Published var errorMessage: String?
    @Published private(set) var userCoordinate: CLLocationCoordinate2D?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    private let searchService: PlaceSearchService
    private let locationService: LocationService
    private var locationObserver: UUID?
    private var hasCenteredOnUser = false

    init(searchService: PlaceSearchService = PlaceSearchService(),
         locationService: LocationService = .shared) {
        self.searchService = searchService
        self.locationService = locationService
        searchService.onSuggestions = { [weak self] results in
            Task { @MainActor in self?.suggestions = results }
        }
        searchService.onError = { [weak self] error in
            Task { @MainActor in
                // MapKit reports "no results" as an error while typing; only show real failures.
                if (error as NSError).code != MKError.placemarkNotFound.rawValue {
                    self?.errorMessage = AppError.userMessage(for: error)
                }
            }
        }
    }

    // Centres the map on the student once and biases search results to their area.
    func startFollowingLocation() {
        guard locationObserver == nil else { return }
        locationObserver = locationService.observeLocation { [weak self] location in
            Task { @MainActor in self?.handleLocation(location) }
        }
    }

    func stopFollowingLocation() {
        if let locationObserver {
            locationService.removeObserver(locationObserver)
        }
        locationObserver = nil
    }

    private func handleLocation(_ location: CLLocation) {
        userCoordinate = location.coordinate
        let nearby = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        searchService.setSearchRegion(nearby)
        if !hasCenteredOnUser && destination == nil {
            mapRegion = nearby
        }
        hasCenteredOnUser = true
    }

    func select(_ suggestion: PlaceSuggestion) async -> Bool {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }
        do {
            let place = try await searchService.resolve(suggestion)
            destination = place
            mapRegion = MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            searchText = ""
            suggestions = []
            return true
        } catch {
            errorMessage = AppError.userMessage(for: error)
            return false
        }
    }

    func centerOnUser() {
        guard let userCoordinate else { return }
        mapRegion = MKCoordinateRegion(
            center: userCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func showRoute(to destination: Destination) {
        if let region = MKCoordinateRegion.fitting([destination.coordinate] + [userCoordinate].compactMap { $0 }) {
            mapRegion = region
        }
    }

    func clearDestination() {
        destination = nil
        searchText = ""
        suggestions = []
    }
}
