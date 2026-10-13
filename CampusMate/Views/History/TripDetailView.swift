import SwiftUI

struct TripDetailView: View {
    @StateObject var viewModel: TripDetailViewModel

    private var trip: Trip { viewModel.trip }

    var body: some View {
        List {
            Section {
                ZStack {
                    TripMapView(
                        studentName: "Last position",
                        studentCoordinate: viewModel.path.last?.coordinate ?? trip.lastCoordinate,
                        isStale: false,
                        destination: trip.destination,
                        path: viewModel.path.map(\.coordinate),
                        focusKey: "\(trip.id ?? "")-\(viewModel.path.count)"
                    )
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(12)
                    }
                }
                .frame(height: 280)
                .listRowInsets(EdgeInsets())
            }

            Section("Destination") {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination.name).font(.headline)
                    if !trip.destination.address.isEmpty {
                        Text(trip.destination.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Journey") {
                LabeledContent("Started", value: trip.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let endedAt = trip.endedAt {
                    LabeledContent("Ended", value: endedAt.formatted(date: .omitted, time: .shortened))
                }
                if let duration = trip.duration {
                    LabeledContent("Duration", value: Formatters.duration(duration))
                }
                LabeledContent("Distance", value: viewModel.path.count > 1 ? Formatters.distance(viewModel.distance) : "-")
                LabeledContent("Location updates", value: "\(viewModel.path.count)")
                LabeledContent("Shared with", value: "\(max(trip.memberIds.count - 1, 0)) member(s)")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(viewModel: TripDetailViewModel(trip: Trip(
            studentId: "alex",
            studentName: "Alex Perera",
            groupIds: ["family"],
            memberIds: ["alex", "maya"],
            status: .completed,
            destination: Destination(name: "NIBM Colombo", address: "Colombo 07", latitude: 6.9063, longitude: 79.8706),
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date().addingTimeInterval(-300)
        )))
    }
}
