import SwiftUI

struct TripHistoryView: View {
    @ObservedObject var viewModel: TripHistoryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading journeys…")
                } else if let errorMessage = viewModel.errorMessage, viewModel.pastTrips.isEmpty {
                    EmptyStateView(systemImage: "exclamationmark.triangle",
                                   title: "Couldn't load journeys",
                                   message: errorMessage)
                } else if viewModel.pastTrips.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.arrow.circlepath",
                        title: "No journeys yet",
                        message: "Journeys you finish will appear here with their route and duration."
                    )
                } else {
                    List(viewModel.pastTrips) { trip in
                        NavigationLink {
                            TripDetailView(viewModel: TripDetailViewModel(trip: trip))
                        } label: {
                            TripHistoryRow(trip: trip)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct TripHistoryRow: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.checkered.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.destination.name)
                    .font(.headline)
                    .lineLimit(1)
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
    TripHistoryView(viewModel: TripHistoryViewModel())
}
