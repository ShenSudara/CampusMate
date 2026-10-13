import Foundation
import CoreLocation

// Streams the student's GPS position to the active trip, throttled by LocationSharingSettings.
final class LiveLocationService {
    static let shared = LiveLocationService()

    private let locationService: LocationService
    private let tripService: TripService
    private let trackerId = UUID()
    private var locationObserver: UUID?
    private var tripId: String?
    private var lastUploaded: CLLocation?
    private var lastUploadAttempt: Date?

    var onUpload: ((Date) -> Void)?
    var onError: ((Error) -> Void)?

    init(locationService: LocationService = .shared, tripService: TripService = .shared) {
        self.locationService = locationService
        self.tripService = tripService
    }

    var isSharing: Bool { tripId != nil }

    // Safe to call again, e.g. after location permission is granted.
    func startSharing(tripId: String) {
        if self.tripId == tripId {
            locationService.startUpdating(for: trackerId, inBackground: true)
            return
        }
        stopSharing()
        self.tripId = tripId
        locationObserver = locationService.observeLocation { [weak self] location in
            self?.handle(location)
        }
        locationService.startUpdating(for: trackerId, inBackground: true)
    }

    func stopSharing() {
        if let locationObserver {
            locationService.removeObserver(locationObserver)
        }
        locationService.stopUpdating(for: trackerId)
        locationObserver = nil
        tripId = nil
        lastUploaded = nil
        lastUploadAttempt = nil
    }

    private func handle(_ location: CLLocation) {
        guard let tripId,
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= LocationSharingSettings.maximumAcceptedAccuracy,
              abs(location.timestamp.timeIntervalSinceNow) <= LocationSharingSettings.maximumLocationAge,
              shouldUpload(location) else { return }

        lastUploadAttempt = Date()
        lastUploaded = location
        tripService.uploadLocation(LocationPoint(location: location), tripId: tripId) { [weak self] error in
            if let error {
                self?.onError?(error)
            } else {
                self?.onUpload?(location.timestamp)
            }
        }
    }

    private func shouldUpload(_ location: CLLocation) -> Bool {
        guard let lastUploaded, let lastUploadAttempt else { return true }
        let elapsed = Date().timeIntervalSince(lastUploadAttempt)
        if elapsed < LocationSharingSettings.minimumUploadInterval { return false }
        if elapsed >= LocationSharingSettings.maximumUploadInterval { return true }
        return location.distance(from: lastUploaded) >= LocationSharingSettings.minimumUploadDistance
    }
}
