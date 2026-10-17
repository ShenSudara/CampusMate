import SwiftUI

struct GuardianHomeView: View {
    @ObservedObject var viewModel: GuardianViewModel
    let currentUser: AppUser?

    var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading students…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.students.isEmpty {
            EmptyStateView(
                systemImage: "person.2.slash",
                title: "No students to follow",
                message: "When members of your groups are in Student mode, they appear here and you can follow their journeys live."
            )
            .frame(maxHeight: .infinity)
        } else {
            mapContent
        }
    }

    private var mapContent: some View {
        let trip = viewModel.selectedTrip
        let stale = trip.map(viewModel.isStale) ?? false
        let pathCoordinates = viewModel.path.map(\.coordinate) + [trip?.lastCoordinate].compactMap { $0 }

        return ZStack {
            TripMapView(
                studentName: viewModel.selectedStudent?.displayName,
                studentCoordinate: trip?.lastCoordinate,
                isStale: stale,
                destination: trip?.destination,
                path: pathCoordinates,
                focusKey: (viewModel.selectedStudentId ?? "") + (trip?.id ?? "")
            )
            .ignoresSafeArea(edges: .top)
            .accessibilityElement()
            .accessibilityLabel(mapAccessibilityLabel(trip: trip, isStale: stale))

            VStack(spacing: 8) {
                StudentPickerView(students: viewModel.students,
                                  selectedId: viewModel.selectedStudentId,
                                  onSelect: viewModel.select)

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()

                if let student = viewModel.selectedStudent {
                    VStack(spacing: 8) {
                        TripStatusCard(student: student, isStale: stale)
                        if student.isTravelling {
                            CheckInPanel(
                                studentName: student.displayName,
                                latestPing: viewModel.latestPingForSelectedTrip,
                                canSend: viewModel.canSendPing,
                                isSending: viewModel.isSendingPing,
                                onSend: { Task { await viewModel.sendCheckIn(from: currentUser) } }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func mapAccessibilityLabel(trip: Trip?, isStale: Bool) -> String {
        guard let name = viewModel.selectedStudent?.displayName else { return "Map" }
        guard let trip else { return "Map. \(name) is not on a journey." }
        let status = isStale ? "Location signal lost." : "Live location shown."
        return "Map of \(name)'s journey to \(trip.destination.name). \(status)"
    }
}

#Preview {
    GuardianHomeView(viewModel: GuardianViewModel(), currentUser: nil)
}
