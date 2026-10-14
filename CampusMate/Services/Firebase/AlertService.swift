import Foundation
import FirebaseFirestore

final class AlertService {
    static let shared = AlertService()

    private lazy var db = Firestore.firestore()
    private lazy var alerts = db.collection("alerts")
    private lazy var pings = db.collection("pings")

    func listenToAlertsVisible(to memberId: String,
                               onChange: @escaping (Result<[SafetyAlert], Error>) -> Void) -> ListenerRegistration {
        alerts
            .whereField("memberIds", arrayContains: memberId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                let result = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: SafetyAlert.self) }
                    .sorted { $0.createdAt > $1.createdAt }
                onChange(.success(result))
            }
    }

    func createAlert(_ alert: SafetyAlert) async throws {
        try alerts.document().setData(from: alert)
    }

    // Marks an unanswered ping as missed and raises one alert for it. Several guardians may
    // detect the same ping at once; the transaction and the fixed alert id keep it to one alert.
    func markPingMissed(_ ping: CheckInPing, detectedBy uid: String, trip: Trip?) async throws {
        guard let pingId = ping.id else { return }
        let pingRef = pings.document(pingId)
        let alertRef = alerts.document("missed-\(pingId)")

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let current = try transaction.getDocument(pingRef).data(as: CheckInPing.self)
                guard current.status == .pending, Date() >= current.deadline else { return nil }

                transaction.updateData(["status": CheckInStatus.missed.rawValue], forDocument: pingRef)
                let alert = SafetyAlert(
                    type: .missedCheckIn,
                    studentId: current.studentId,
                    studentName: current.studentName,
                    tripId: current.tripId,
                    memberIds: current.memberIds,
                    message: "\(current.studentName) didn't respond to \(current.senderName)'s check-in.",
                    createdAt: Date(),
                    createdBy: uid,
                    latitude: trip?.lastLatitude,
                    longitude: trip?.lastLongitude
                )
                try transaction.setData(from: alert, forDocument: alertRef)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }
}
