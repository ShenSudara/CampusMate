import SwiftUI
import MapKit

struct DestinationMapView: View {
    @ObservedObject var viewModel: StudentHomeViewModel
    @FocusState private var isSearchFocused: Bool

    private var showsSuggestions: Bool {
        isSearchFocused && !viewModel.searchText.isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $viewModel.mapRegion,
                annotationItems: viewModel.destination.map { [$0] } ?? []) { place in
                MapMarker(coordinate: place.coordinate, tint: .red)
            }
            .ignoresSafeArea(edges: .top)
            .onTapGesture { isSearchFocused = false }

            VStack(spacing: 8) {
                searchBar

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }

                if showsSuggestions {
                    suggestionList
                }

                Spacer()

                if let destination = viewModel.destination, !showsSuggestions {
                    selectedCard(for: destination)
                }
            }
            .padding()

            if viewModel.isResolving {
                ProgressView("Finding place…")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Where are you going?", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    private var suggestionList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if viewModel.suggestions.isEmpty {
                    Text("No places found for \"\(viewModel.searchText)\".")
                        .foregroundColor(.secondary)
                        .padding()
                }
                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        isSearchFocused = false
                        Task { await viewModel.select(suggestion) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .foregroundColor(.primary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .disabled(viewModel.isResolving)
                    Divider().padding(.leading, 52)
                }
            }
        }
        .frame(maxHeight: 320)
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func selectedCard(for destination: Destination) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(.headline)
                if !destination.address.isEmpty {
                    Text(destination.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive, action: viewModel.clearDestination) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove destination")
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }
}

#Preview {
    DestinationMapView(viewModel: StudentHomeViewModel())
}
