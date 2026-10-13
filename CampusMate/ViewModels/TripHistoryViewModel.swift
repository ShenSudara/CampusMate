import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

@MainActor
final class TripHistoryViewModel: ObservableObject {
    struct StudentFilter: Identifiable, Hashable {
        let id: String
        let name: String
    }

    @Published private(set) var myTrips: [Trip] = []
    @Published private(set) var sharedTrips: [Trip] = []
    @Published private(set) var isLoadingMine = true
    @Published private(set) var isLoadingShared = true
    @Published var selectedStudentId: String?
    @Published var errorMessage: String?

    private let tripService: TripService
    private var myListener: ListenerRegistration?
    private var sharedListener: ListenerRegistration?

    init(tripService: TripService = .shared) {
        self.tripService = tripService
    }

    // Student mode: the user's own finished journeys.
    var myPastTrips: [Trip] { myTrips.filter { $0.status == .completed } }

    // Guardian mode: finished journeys of other members, optionally for one student.
    var sharedPastTrips: [Trip] {
        sharedTrips.filter { $0.status == .completed && (selectedStudentId == nil || $0.studentId == selectedStudentId) }
    }

    var studentFilters: [StudentFilter] {
        var seen = Set<String>()
        return sharedTrips
            .filter { $0.status == .completed && seen.insert($0.studentId).inserted }
            .map { StudentFilter(id: $0.studentId, name: $0.studentName) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var selectedStudentName: String? {
        studentFilters.first { $0.id == selectedStudentId }?.name
    }

    func start(uid: String) {
        guard myListener == nil else { return }
        myListener = tripService.listenToTrips(studentId: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.handle(result) { self.myTrips = $0 }
                self.isLoadingMine = false
            }
        }
        sharedListener = tripService.listenToSharedTrips(memberId: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.handle(result) { self.sharedTrips = $0 }
                self.isLoadingShared = false
            }
        }
    }

    func stop() {
        myListener?.remove()
        sharedListener?.remove()
        myListener = nil
        sharedListener = nil
        myTrips = []
        sharedTrips = []
        selectedStudentId = nil
        isLoadingMine = true
        isLoadingShared = true
    }

    private func handle(_ result: Result<[Trip], Error>, apply: ([Trip]) -> Void) {
        switch result {
        case .success(let trips):
            apply(trips)
            errorMessage = nil
        case .failure(let error):
            errorMessage = AppError.userMessage(for: error)
        }
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
