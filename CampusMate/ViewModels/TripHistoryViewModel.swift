import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

@MainActor
final class TripHistoryViewModel: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    private let tripService: TripService
    private var listener: ListenerRegistration?

    init(tripService: TripService = .shared) {
        self.tripService = tripService
    }

    var pastTrips: [Trip] { trips.filter { $0.status == .completed } }

    func start(uid: String) {
        guard listener == nil else { return }
        listener = tripService.listenToTrips(studentId: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let trips):
                    self.trips = trips
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
                self.isLoading = false
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        trips = []
        isLoading = true
    }
}

@MainActor
final class TripDetailViewModel: ObservableObject {
    @Published private(set) var path: [LocationPoint] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let trip: Trip
    private let tripService: TripService

    init(trip: Trip, tripService: TripService = .shared) {
        self.trip = trip
        self.tripService = tripService
    }

    var distance: CLLocationDistance {
        zip(path, path.dropFirst()).reduce(0) { total, pair in
            let from = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
            let to = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
            return total + to.distance(from: from)
        }
    }

    func load() async {
        guard let tripId = trip.id, path.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            path = try await tripService.fetchPath(tripId: tripId)
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }
}
