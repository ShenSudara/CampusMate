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
    @Published private(set) var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    // Incremented whenever the app moves the map, so user panning is not overridden.
    @Published private(set) var regionChangeId = 0
    @Published private(set) var route: RouteInfo?
    @Published private(set) var isRouting = false
    @Published private(set) var routeError: String?

    private let searchService: PlaceSearchService
    private let locationService: LocationService
    private let routeService: RouteService
    private var routeTarget: Destination?
    private var locationObserver: UUID?
    private var hasCenteredOnUser = false

    init(searchService: PlaceSearchService = PlaceSearchService(),
         locationService: LocationService = .shared,
         routeService: RouteService = .shared) {
        self.searchService = searchService
        self.locationService = locationService
        self.routeService = routeService
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
            setRegion(nearby)
        }
        hasCenteredOnUser = true
        // A destination picked before the first GPS fix still needs its route.
        if let routeTarget, route == nil, !isRouting {
            Task { await loadRoute(to: routeTarget) }
        }
    }

    func select(_ suggestion: PlaceSuggestion) async -> Bool {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }
        do {
            let place = try await searchService.resolve(suggestion)
            destination = place
            searchText = ""
            suggestions = []
            showRoute(to: place)
            return true
        } catch {
            errorMessage = AppError.userMessage(for: error)
            return false
        }
    }

    func centerOnUser() {
        guard let userCoordinate else { return }
        setRegion(MKCoordinateRegion(
            center: userCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    // Fits the map to the user and destination, then draws the suggested route.
    func showRoute(to destination: Destination) {
        if let region = MKCoordinateRegion.fitting([destination.coordinate] + [userCoordinate].compactMap { $0 }) {
            setRegion(region)
        }
        if routeTarget != destination || route == nil {
            routeTarget = destination
            route = nil
            Task { await loadRoute(to: destination) }
        }
    }

    private func loadRoute(to destination: Destination) async {
        guard let start = userCoordinate else { return }
        isRouting = true
        routeError = nil
        defer { isRouting = false }
        do {
            let result = try await routeService.route(from: start, to: destination.coordinate)
            // Ignore a late result for a destination that is no longer selected.
            guard routeTarget == destination else { return }
            route = result
            let rect = result.polyline.boundingMapRect
            var region = MKCoordinateRegion(rect)
            region.span.latitudeDelta *= 1.3
            region.span.longitudeDelta *= 1.3
            setRegion(region)
        } catch {
            guard routeTarget == destination else { return }
            routeError = "Couldn't find a route. The destination is still shown on the map."
        }
    }

    private func setRegion(_ region: MKCoordinateRegion) {
        mapRegion = region
        regionChangeId += 1
    }

    func clearRoute() {
        routeTarget = nil
        route = nil
        routeError = nil
    }

    func clearDestination() {
        clearRoute()
        destination = nil
        searchText = ""
        suggestions = []
    }
}
