import Foundation
import FirebaseFirestore

enum CheckInStatus: String, Codable {
    case pending
    case acknowledged
    case missed
}

struct CheckInPing: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var tripId: String
    var studentId: String
    var studentName: String
    var senderId: String
    var senderName: String
    // Everyone who can see the trip; used for queries and security rules.
    var memberIds: [String]
    var sentAt: Date
    var deadline: Date
    var status: CheckInStatus
    var respondedAt: Date?

    func isExpired(at date: Date = Date()) -> Bool {
        status == .pending && date >= deadline
    }

    func secondsLeft(at date: Date = Date()) -> Int {
        max(0, Int(deadline.timeIntervalSince(date).rounded(.up)))
    }
}
