import Foundation
import FirebaseFirestore

struct GroupMember: Codable, Equatable {
    var email: String
    var displayName: String
}

// A group protects one student (its creator and admin); every other member is a guardian.
struct TrustedGroup: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var adminId: String
    var studentId: String
    var memberIds: [String]
    var members: [String: GroupMember]
    var createdAt: Date

    var guardianIds: [String] { memberIds.filter { $0 != studentId } }

    func isAdmin(_ uid: String) -> Bool { adminId == uid }

    func member(_ uid: String) -> GroupMember? { members[uid] }

    var studentName: String { members[studentId]?.displayName ?? "Student" }
}
