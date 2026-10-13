import Foundation

// A student a guardian can follow, with their active trip if they are travelling.
struct WatchedStudent: Identifiable, Equatable {
    let id: String
    let displayName: String
    let email: String
    var groupNames: [String]
    var activeTrip: Trip?

    var isTravelling: Bool { activeTrip != nil }
}
