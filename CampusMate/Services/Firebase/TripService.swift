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

    // Active trips this user can watch, i.e. trips of other members of their groups.
    func listenToWatchableTrips(memberId: String,
                                onChange: @escaping (Result<[Trip], Error>) -> Void) -> ListenerRegistration {
        trips
            .whereField("memberIds", arrayContains: memberId)
            .whereField("status", isEqualTo: TripStatus.active.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                let result = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: Trip.self) }
                    .filter { $0.studentId != memberId }
                onChange(.success(result))
            }
    }

    func listenToPath(tripId: String,
                      onChange: @escaping (Result<[LocationPoint], Error>) -> Void) -> ListenerRegistration {
        trips.document(tripId).collection("locations")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                onChange(.success((snapshot?.documents ?? []).compactMap { try? $0.data(as: LocationPoint.self) }))
            }
    }

    // All of a student's trips; sorted on the device so no composite index is needed.
    func listenToTrips(studentId: String,
                       onChange: @escaping (Result<[Trip], Error>) -> Void) -> ListenerRegistration {
        trips
            .whereField("studentId", isEqualTo: studentId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                let result = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: Trip.self) }
                    .sorted { $0.startedAt > $1.startedAt }
                onChange(.success(result))
            }
    }

    // Every trip shared with this user by other members; sorted on the device.
    func listenToSharedTrips(memberId: String,
                             onChange: @escaping (Result<[Trip], Error>) -> Void) -> ListenerRegistration {
        trips
            .whereField("memberIds", arrayContains: memberId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                let result = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: Trip.self) }
                    .filter { $0.studentId != memberId }
                    .sorted { $0.startedAt > $1.startedAt }
                onChange(.success(result))
            }
    }

    // Deletes a finished trip with its breadcrumb points. Firestore does not delete
    // subcollections automatically, so the points are removed in batches first.
    func deleteTrip(tripId: String) async throws {
        let tripRef = trips.document(tripId)
        let points = try await tripRef.collection("locations").getDocuments().documents
        for chunk in stride(from: 0, to: points.count, by: 400).map({ Array(points[$0..<min($0 + 400, points.count)]) }) {
            let batch = db.batch()
            chunk.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        }
        try await tripRef.delete()
    }

    func fetchPath(tripId: String) async throws -> [LocationPoint] {
        let snapshot = try await trips.document(tripId).collection("locations")
            .order(by: "timestamp")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: LocationPoint.self) }
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

    // Saves the latest position on the trip and adds it to the breadcrumb trail.
    // Firestore queues the write while offline, so this does not wait for the server.
    func uploadLocation(_ point: LocationPoint, tripId: String, completion: @escaping (Error?) -> Void) {
        let tripRef = trips.document(tripId)
        let batch = db.batch()
        var tripUpdate: [String: Any] = [
            "lastLatitude": point.latitude,
            "lastLongitude": point.longitude,
            "lastLocationAt": Timestamp(date: point.timestamp)
        ]
        tripUpdate["lastSpeed"] = point.speed ?? FieldValue.delete()
        batch.updateData(tripUpdate, forDocument: tripRef)
        do {
            try batch.setData(from: point, forDocument: tripRef.collection("locations").document())
        } catch {
            completion(error)
            return
        }
        batch.commit(completion: completion)
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

