import SwiftUI

struct GuardianHomeView: View {
    @ObservedObject var viewModel: GuardianViewModel

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

            VStack(spacing: 8) {
                StudentPickerView(students: viewModel.students,
                                  selectedId: viewModel.selectedStudentId,
                                  onSelect: viewModel.select)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
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
                    TripStatusCard(student: student, isStale: stale)
                        .padding()
                }
            }
        }
    }
}

#Preview {
    GuardianHomeView(viewModel: GuardianViewModel())
}
