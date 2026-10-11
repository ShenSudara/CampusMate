import SwiftUI

struct DestinationPickerView: View {
    @ObservedObject var viewModel: StudentHomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                if viewModel.searchText.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "Where are you going?",
                        message: "Search for a hostel, campus building, station or any address."
                    )
                    .listRowBackground(Color.clear)
                } else if viewModel.suggestions.isEmpty {
                    Text("No places found for \"\(viewModel.searchText)\".")
                        .foregroundColor(.secondary)
                }

                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        Task {
                            if await viewModel.select(suggestion) {
                                dismiss()
                            }
                        }
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
                        }
                    }
                    .disabled(viewModel.isResolving)
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search for a place")
            .autocorrectionDisabled()
            .overlay {
                if viewModel.isResolving {
                    ProgressView("Finding place…")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                }
            }
            .navigationTitle("Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { viewModel.errorMessage = nil }
        }
    }
}

#Preview {
    DestinationPickerView(viewModel: StudentHomeViewModel())
}
