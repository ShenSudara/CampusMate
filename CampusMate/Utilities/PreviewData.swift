#if DEBUG
import Foundation
import FirebaseCore

// Sample objects used only by SwiftUI previews.
enum PreviewData {
    static let studentId = "preview-student"
    static let guardianId = "preview-guardian"

    // Previews do not run the app delegate, so Firebase must be set up here.
    static func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    static let student = AppUser(
        id: studentId,
        email: "alex@example.com",
        displayName: "Alex Perera",
        activeMode: .student,
        createdAt: Date()
    )

    static let guardian = AppUser(
        id: guardianId,
        email: "maya@example.com",
        displayName: "Maya Perera",
        activeMode: .guardian,
        createdAt: Date()
    )

    static let group = TrustedGroup(
        id: "preview-group-family",
        name: "Family",
        adminId: studentId,
        studentId: studentId,
        memberIds: [studentId, guardianId],
        members: [
            studentId: GroupMember(email: student.email, displayName: student.displayName, activeMode: .student),
            guardianId: GroupMember(email: guardian.email, displayName: guardian.displayName, activeMode: .guardian)
        ],
        createdAt: Date()
    )

    static let guardedGroup = TrustedGroup(
        id: "preview-group-friends",
        name: "Campus Friends",
        adminId: "preview-other-student",
        studentId: "preview-other-student",
        memberIds: ["preview-other-student", studentId],
        members: [
            "preview-other-student": GroupMember(email: "sam@example.com", displayName: "Sam Silva", activeMode: .student),
            studentId: GroupMember(email: student.email, displayName: student.displayName, activeMode: .student)
        ],
        createdAt: Date().addingTimeInterval(-86_400)
    )
}
#endif
