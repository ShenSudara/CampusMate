import SwiftUI

// Horizontal chips for switching between the students a guardian follows.
struct StudentPickerView: View {
    let students: [WatchedStudent]
    let selectedId: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(students) { student in
                    let isSelected = student.id == selectedId
                    Button {
                        onSelect(student.id)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(student.isTravelling ? Color.green : Color.secondary.opacity(0.4))
                                .frame(width: 8, height: 8)
                            Text(student.displayName)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor : Color(.systemBackground).opacity(0.9))
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                    }
                    .accessibilityLabel("\(student.displayName), \(student.isTravelling ? "travelling" : "not travelling")")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    StudentPickerView(
        students: [
            WatchedStudent(id: "alex", displayName: "Alex Perera", email: "alex@example.com", groupNames: ["Family"]),
            WatchedStudent(id: "sam", displayName: "Sam Silva", email: "sam@example.com", groupNames: ["Friends"])
        ],
        selectedId: "alex",
        onSelect: { _ in }
    )
}
