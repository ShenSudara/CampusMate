import Foundation
import FirebaseFirestore
import CoreLocation

final class TripService {
    static let shared = TripService()

    private lazy var db = Firestore.firestore()
    private lazy var trips = db.collection("trips")

    func listenToActiveTrip(studentId: String,
                            onChange: @escaping (Result<Trip?, Error>) -> Void) -> ListenerRegistration {
        trips
            .whereField("studentId", isEqualTo: studentId)
            .whereField("status", isEqualTo: TripStatus.active.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                let trip = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: Trip.self) }
                    .max { $0.startedAt < $1.startedAt }
                onChange(.success(trip))
            }
    }

    // Creates the trip and links it to the user's profile in one write.
    func startTrip(student: AppUser, groups: [TrustedGroup], destination: Destination,
                   location: CLLocationCoordinate2D?) async throws -> String {
        let memberIds = Array(Set(groups.flatMap(\.memberIds) + [student.uid]))
        let trip = Trip(
            studentId: student.uid,
            studentName: student.displayName,
            groupIds: groups.compactMap(\.id),
            memberIds: memberIds,
            status: .active,
            destination: destination,
            startedAt: Date(),
            lastLatitude: location?.latitude,
            lastLongitude: location?.longitude,
            lastLocationAt: location == nil ? nil : Date()
        )
        let tripRef = trips.document()
        let batch = db.batch()
        try batch.setData(from: trip, forDocument: tripRef)
        batch.updateData(["activeTripId": tripRef.documentID], forDocument: db.collection("users").document(student.uid))
        try await batch.commit()
        return tripRef.documentID
    }

    func endTrip(tripId: String, studentId: String) async throws {
        let batch = db.batch()
        batch.updateData([
            "status": TripStatus.completed.rawValue,
            "endedAt": FieldValue.serverTimestamp()
        ], forDocument: trips.document(tripId))
        batch.updateData(["activeTripId": FieldValue.delete()], forDocument: db.collection("users").document(studentId))
        try await batch.commit()
    }
}

