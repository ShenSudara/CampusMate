import Foundation

enum UserMode: String, Codable, CaseIterable, Identifiable {
    case student
    case guardian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: return "Student"
        case .guardian: return "Guardian"
        }
    }

    var systemImage: String {
        switch self {
        case .student: return "figure.walk"
        case .guardian: return "shield.lefthalf.filled"
        }
    }
}
