import Foundation
import FirebaseFirestore
import CoreLocation

enum AlertType: String, Codable {
    case missedCheckIn
    case motionDetected
    case sos

    var title: String {
        switch self {
        case .missedCheckIn: return "Missed check-in"
        case .motionDetected: return "Possible emergency"
        case .sos: return "SOS"
        }
    }

    // SOS and possible emergencies are shown in red, missed check-ins in orange.
    var isCritical: Bool { self != .missedCheckIn }

    var systemImage: String {
        switch self {
        case .missedCheckIn: return "bell.slash.fill"
        case .motionDetected: return "waveform.path.ecg"
        case .sos: return "sos"
        }
    }
}

struct SafetyAlert: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var type: AlertType
    var studentId: String
    var studentName: String
    var tripId: String
    // Everyone who can see the trip; used for queries and security rules.
    var memberIds: [String]
    var message: String
    var createdAt: Date
    var createdBy: String
    var latitude: Double?
    var longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
