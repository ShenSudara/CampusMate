import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

@MainActor
final class TripViewModel: ObservableObject {
    @Published private(set) var activeTrip: Trip?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isLoading = true
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private let tripService: TripService
    private let locationService: LocationService
    private var tripListener: ListenerRegistration?
    private var authorizationObserver: UUID?

    init(tripService: TripService = .shared, locationService: LocationService = .shared) {
        self.tripService = tripService
        self.locationService = locationService
    }

    var isLocationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var needsLocationPermission: Bool { authorizationStatus == .notDetermined }

    var hasAlwaysPermission: Bool { authorizationStatus == .authorizedAlways }

    func start(uid: String) {
        if authorizationObserver == nil {
            authorizationObserver = locationService.observeAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                    if status == .authorizedWhenInUse || status == .authorizedAlways {
                        self?.locationService.requestCurrentLocation()
                    }
                }
            }
        }
        guard tripListener == nil else { return }
        tripListener = tripService.listenToActiveTrip(studentId: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let trip):
                    self.activeTrip = trip
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
                self.isLoading = false
            }
        }
    }

    func stop() {
        tripListener?.remove()
        tripListener = nil
        if let authorizationObserver {
            locationService.removeObserver(authorizationObserver)
        }
        authorizationObserver = nil
        activeTrip = nil
        isLoading = true
    }

    func requestLocationPermission() {
        errorMessage = nil
        do {
            try locationService.requestWhenInUse()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    func startTrip(student: AppUser?, groups: [TrustedGroup], destination: Destination?) async {
        errorMessage = nil
        guard let student else { return }
        guard let destination else {
            errorMessage = "Choose a destination before starting your journey."
            return
        }
        guard groups.contains(where: { $0.memberIds.count > 1 }) else {
            errorMessage = "Add at least one other member to a group so someone can follow your journey."
            return
        }
        if needsLocationPermission {
            requestLocationPermission()
            return
        }
        guard locationService.isAuthorized else {
            errorMessage = "Location access is off. Turn it on in Settings to share your journey."
            return
        }

        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await tripService.startTrip(
                student: student,
                groups: groups,
                destination: destination,
                location: locationService.lastLocation?.coordinate
            )
            // Background sharing needs "Always"; iOS shows this prompt only after "When In Use".
            locationService.requestAlways()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    func endTrip() async {
        guard let trip = activeTrip, let tripId = trip.id else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await tripService.endTrip(tripId: tripId, studentId: trip.studentId)
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }
}
