import Foundation
import CoreLocation

// Tuning values for live location sharing during a journey.
enum LocationSharingSettings {
    // Upload at least this often while the student is moving or standing still.
    static let maximumUploadInterval: TimeInterval = 15
    // Upload sooner than the interval once the student has moved this far.
    static let minimumUploadDistance: CLLocationDistance = 25
    // Never upload more often than this, even when moving fast.
    static let minimumUploadInterval: TimeInterval = 5
    // Ignore fixes less accurate than this (in metres).
    static let maximumAcceptedAccuracy: CLLocationAccuracy = 100
    // Ignore cached fixes older than this, e.g. a position from before the journey started.
    static let maximumLocationAge: TimeInterval = 30
    // Guardians see "Signal lost" when the newest update is older than this.
    static let staleLocationThreshold: TimeInterval = 120
}
