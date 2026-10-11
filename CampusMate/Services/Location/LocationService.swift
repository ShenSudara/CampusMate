import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var authorizationHandlers: [UUID: (CLAuthorizationStatus) -> Void] = [:]
    private var locationHandlers: [UUID: (CLLocation) -> Void] = [:]
    private var activeTrackers = Set<UUID>()

    private(set) var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = false
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // Setting allowsBackgroundLocationUpdates without the "location" background mode crashes the app.
    private var hasBackgroundMode: Bool {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        return modes.contains("location")
    }

    private var hasUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
    }

    func observeAuthorization(_ handler: @escaping (CLAuthorizationStatus) -> Void) -> UUID {
        let id = UUID()
        authorizationHandlers[id] = handler
        handler(authorizationStatus)
        return id
    }

    func observeLocation(_ handler: @escaping (CLLocation) -> Void) -> UUID {
        let id = UUID()
        locationHandlers[id] = handler
        if let lastLocation { handler(lastLocation) }
        return id
    }

    func removeObserver(_ id: UUID) {
        authorizationHandlers[id] = nil
        locationHandlers[id] = nil
        stopUpdating(for: id)
    }

    func requestWhenInUse() throws {
        guard hasUsageDescription else {
            throw AppError.message("Location permission is not set up in this build of the app.")
        }
        manager.requestWhenInUseAuthorization()
    }

    // iOS only shows the "Always" prompt after "When In Use" has been granted.
    func requestAlways() {
        guard hasUsageDescription, authorizationStatus == .authorizedWhenInUse else { return }
        manager.requestAlwaysAuthorization()
    }

    func requestCurrentLocation() {
        guard isAuthorized else { return }
        manager.requestLocation()
    }

    // Several features can need updates at once; GPS stays on until the last one stops.
    func startUpdating(for id: UUID, inBackground: Bool) {
        guard isAuthorized else { return }
        activeTrackers.insert(id)
        if inBackground && hasBackgroundMode {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }
        manager.startUpdatingLocation()
    }

    func stopUpdating(for id: UUID) {
        guard activeTrackers.remove(id) != nil, activeTrackers.isEmpty else { return }
        manager.stopUpdatingLocation()
        if hasBackgroundMode {
            manager.allowsBackgroundLocationUpdates = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationHandlers.values.forEach { $0(status) }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        locationHandlers.values.forEach { $0(location) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A temporary failure to get a fix is normal; CoreLocation keeps trying.
    }
}
