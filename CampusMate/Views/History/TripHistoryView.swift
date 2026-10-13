import SwiftUI

struct TripHistoryView: View {
    @ObservedObject var viewModel: TripHistoryViewModel
    let mode: UserMode

    private var trips: [Trip] {
        mode == .student ? viewModel.myPastTrips : viewModel.sharedPastTrips
    }

    private var isLoading: Bool {
        mode == .student ? viewModel.isLoadingMine : viewModel.isLoadingShared
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading journeys…")
                } else if let errorMessage = viewModel.errorMessage, trips.isEmpty {
                    EmptyStateView(systemImage: "exclamationmark.triangle",
                                   title: "Couldn't load journeys",
                                   message: errorMessage)
                } else if trips.isEmpty {
                    emptyState
                } else {
                    List(trips) { trip in
                        NavigationLink {
                            TripDetailView(viewModel: TripDetailViewModel(trip: trip))
                        } label: {
                            TripHistoryRow(trip: trip, showsStudent: mode == .guardian)
                        }
                    }
                }
            }
            .navigationTitle(mode == .student ? "My Journeys" : "Student Journeys")
            .toolbar {
                if mode == .guardian && !viewModel.studentFilters.isEmpty {
                    studentFilterMenu
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if mode == .student {
            EmptyStateView(
                systemImage: "clock.arrow.circlepath",
                title: "No journeys yet",
                message: "Journeys you finish will appear here with their route and duration."
            )
        } else if let name = viewModel.selectedStudentName {
            EmptyStateView(
                systemImage: "clock.arrow.circlepath",
                title: "No journeys for \(name)",
                message: "Choose another student or show everyone."
            )
        } else {
            EmptyStateView(
                systemImage: "clock.arrow.circlepath",
                title: "No journeys yet",
                message: "Finished journeys of students in your groups will appear here."
            )
        }
    }

    private var studentFilterMenu: some View {
        Menu {
            Picker("Student", selection: $viewModel.selectedStudentId) {
                Text("All Students").tag(String?.none)
                ForEach(viewModel.studentFilters) { student in
                    Text(student.name).tag(Optional(student.id))
                }
            }
        } label: {
            Label(viewModel.selectedStudentName ?? "All Students",
                  systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter by student")
    }
}

struct TripHistoryRow: View {
    let trip: Trip
    var showsStudent = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: showsStudent ? "person.crop.circle.fill" : "flag.checkered.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                if showsStudent {
                    Text(trip.studentName)
                        .font(.headline)
                    Label(trip.destination.name, systemImage: "flag.checkered")
                        .font(.subheadline)
                        .lineLimit(1)
                } else {
                    Text(trip.destination.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(trip.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let duration = trip.duration {
                Text(Formatters.duration(duration))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    TripHistoryView(viewModel: TripHistoryViewModel(), mode: .guardian)
}
