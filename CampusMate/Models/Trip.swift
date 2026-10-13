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

    var lastCoordinate: CLLocationCoordinate2D? {
        guard let lastLatitude, let lastLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
    }
}
