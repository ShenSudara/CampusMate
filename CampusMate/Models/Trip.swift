import Foundation
import FirebaseFirestore
import CoreLocation

enum TripStatus: String, Codable {
    case active
    case completed
}

struct Trip: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var studentId: String
    var studentName: String
    var groupIds: [String]
    // Everyone in the student's groups; used for queries and security rules.
    var memberIds: [String]
    var status: TripStatus
    var destination: Destination
    var startedAt: Date
    var endedAt: Date?
    var lastLatitude: Double?
    var lastLongitude: Double?
    var lastLocationAt: Date?
    var lastSpeed: Double?
    // Set when the student ends the journey by confirming they reached the destination.
    var arrivedSafely: Bool?

    var didArriveSafely: Bool { arrivedSafely == true }

    var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    func isLocationStale(at date: Date = Date()) -> Bool {
        guard let lastLocationAt else { return true }
        return date.timeIntervalSince(lastLocationAt) > LocationSharingSettings.staleLocationThreshold
    }

    var lastCoordinate: CLLocationCoordinate2D? {
        guard let lastLatitude, let lastLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
    }
}
