import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class GuardianViewModel: ObservableObject {
    @Published private(set) var students: [WatchedStudent] = []
    @Published private(set) var selectedStudentId: String?
    @Published private(set) var path: [LocationPoint] = []
    @Published private(set) var isLoading = true
    @Published private(set) var now = Date()
    @Published var errorMessage: String?

    private let groupService: GroupService
    private let tripService: TripService
    private let userService: UserService
    private var uid: String?
    private var groups: [TrustedGroup] = []
    private var trips: [Trip] = []
    private var hasLoadedGroups = false
    private var hasLoadedTrips = false
    private var groupListener: ListenerRegistration?
    private var tripListener: ListenerRegistration?
    private var pathListener: ListenerRegistration?
    private var pathTripId: String?
    private var clock: AnyCancellable?

    init(groupService: GroupService = .shared,
         tripService: TripService = .shared,
         userService: UserService = .shared) {
        self.groupService = groupService
        self.tripService = tripService
        self.userService = userService
    }

    var selectedStudent: WatchedStudent? {
        students.first { $0.id == selectedStudentId }
    }

    var selectedTrip: Trip? { selectedStudent?.activeTrip }

    var travellingCount: Int { students.filter(\.isTravelling).count }

    func start(uid: String, savedSelection: String?) {
        guard groupListener == nil else { return }
        self.uid = uid
        selectedStudentId = savedSelection

        groupListener = groupService.listenToGroups(for: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let groups):
                    self.groups = groups
                    self.hasLoadedGroups = true
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
                self.rebuildStudents()
            }
        }
        tripListener = tripService.listenToWatchableTrips(memberId: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let trips):
                    self.trips = trips
                    self.hasLoadedTrips = true
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
                self.rebuildStudents()
            }
        }
        // Refreshes "last updated" labels and the stale-signal check.
        clock = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.now = date }
    }

    func stop() {
        groupListener?.remove()
        tripListener?.remove()
        pathListener?.remove()
        groupListener = nil
        tripListener = nil
        pathListener = nil
        pathTripId = nil
        clock = nil
        students = []
        path = []
        isLoading = true
    }

    func select(_ studentId: String) {
        guard studentId != selectedStudentId else { return }
        selectedStudentId = studentId
        updatePathListener()
        guard let uid else { return }
        Task {
            do {
                try await userService.updateSelectedStudent(uid: uid, studentId: studentId)
            } catch {
                errorMessage = AppError.userMessage(for: error)
            }
        }
    }

    func isStale(_ trip: Trip) -> Bool {
        trip.isLocationStale(at: now)
    }

    // Students are members in Student mode, plus anyone who is travelling right now.
    private func rebuildStudents() {
        guard let uid else { return }
        var result: [String: WatchedStudent] = [:]
        for group in groups {
            for memberId in group.studentIds where memberId != uid {
                guard let member = group.member(memberId) else { continue }
                if result[memberId] == nil {
                    result[memberId] = WatchedStudent(id: memberId, displayName: member.displayName,
                                                      email: member.email, groupNames: [])
                }
                result[memberId]?.groupNames.append(group.name)
            }
        }
        for trip in trips {
            if result[trip.studentId] == nil {
                let groupNames = groups.filter { trip.groupIds.contains($0.id ?? "") }.map(\.name)
                result[trip.studentId] = WatchedStudent(id: trip.studentId, displayName: trip.studentName,
                                                        email: "", groupNames: groupNames)
            }
            result[trip.studentId]?.activeTrip = trip
        }

        students = result.values.sorted {
            if $0.isTravelling != $1.isTravelling { return $0.isTravelling }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        if selectedStudentId == nil || selectedStudent == nil {
            selectedStudentId = students.first?.id
        }
        isLoading = !(hasLoadedGroups && hasLoadedTrips)
        updatePathListener()
    }

    private func updatePathListener() {
        let tripId = selectedTrip?.id
        guard tripId != pathTripId else { return }
        pathListener?.remove()
        pathListener = nil
        pathTripId = tripId
        path = []
        guard let tripId else { return }
        pathListener = tripService.listenToPath(tripId: tripId) { [weak self] result in
            Task { @MainActor in
                guard let self, self.pathTripId == tripId else { return }
                switch result {
                case .success(let points):
                    self.path = points
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
            }
        }
    }
}
