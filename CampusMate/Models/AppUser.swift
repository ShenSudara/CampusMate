import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var activeMode: UserMode
    var selectedStudentId: String?
    var activeTripId: String?
    var createdAt: Date

    var uid: String { id ?? "" }
}
