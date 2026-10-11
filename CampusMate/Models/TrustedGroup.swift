import Foundation
import FirebaseFirestore

struct GroupMember: Codable, Equatable {
    var email: String
    var displayName: String
    var activeMode: UserMode?
}

// A member's role in a group follows their current mode: students share journeys, guardians watch them.
struct TrustedGroup: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var adminId: String
    var memberIds: [String]
    var members: [String: GroupMember]
    var createdAt: Date

    func isAdmin(_ uid: String) -> Bool { adminId == uid }

    func member(_ uid: String) -> GroupMember? { members[uid] }

    var admin: GroupMember? { members[adminId] }

    // Members without a saved mode are treated as students, the default for new accounts.
    func mode(of uid: String) -> UserMode { members[uid]?.activeMode ?? .student }

    var studentIds: [String] { sortedMemberIds.filter { mode(of: $0) == .student } }
    var guardianIds: [String] { sortedMemberIds.filter { mode(of: $0) == .guardian } }

    private var sortedMemberIds: [String] {
        memberIds.sorted {
            (members[$0]?.displayName ?? "").localizedCaseInsensitiveCompare(members[$1]?.displayName ?? "") == .orderedAscending
        }
    }
}
