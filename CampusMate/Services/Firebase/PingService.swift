import Foundation
import FirebaseFirestore

final class PingService {
    static let shared = PingService()

    private lazy var pings = Firestore.firestore().collection("pings")

    func sendPing(trip: Trip, sender: AppUser) async throws {
        guard let tripId = trip.id else { throw AppError.message("This journey is no longer available.") }
        let now = Date()
        let ping = CheckInPing(
            tripId: tripId,
            studentId: trip.studentId,
            studentName: trip.studentName,
            senderId: sender.uid,
            senderName: sender.displayName,
            memberIds: trip.memberIds,
            sentAt: now,
            deadline: now.addingTimeInterval(SafetyThresholds.checkInResponseWindow),
            status: .pending
        )
        try pings.document().setData(from: ping)
    }

    // Pings sent to this student; filtered and sorted on the device to avoid composite indexes.
    func listenToPingsForStudent(_ studentId: String,
                                 onChange: @escaping (Result<[CheckInPing], Error>) -> Void) -> ListenerRegistration {
        pings
            .whereField("studentId", isEqualTo: studentId)
            .addSnapshotListener { snapshot, error in
                onChange(Self.decode(snapshot, error))
            }
    }

    // Pings the user can see as a group member (sent by them or by other guardians).
    func listenToPingsVisible(to memberId: String,
                              onChange: @escaping (Result<[CheckInPing], Error>) -> Void) -> ListenerRegistration {
        pings
            .whereField("memberIds", arrayContains: memberId)
            .addSnapshotListener { snapshot, error in
                onChange(Self.decode(snapshot, error))
            }
    }

    func acknowledge(pingId: String) async throws {
        try await pings.document(pingId).updateData([
            "status": CheckInStatus.acknowledged.rawValue,
            "respondedAt": FieldValue.serverTimestamp()
        ])
    }

    private static func decode(_ snapshot: QuerySnapshot?, _ error: Error?) -> Result<[CheckInPing], Error> {
        if let error { return .failure(error) }
        let result = (snapshot?.documents ?? [])
            .compactMap { try? $0.data(as: CheckInPing.self) }
            .sorted { $0.sentAt > $1.sentAt }
        return .success(result)
    }
}
