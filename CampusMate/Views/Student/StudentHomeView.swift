import SwiftUI

struct StudentHomeView: View {
    @ObservedObject var session: SessionViewModel
    @StateObject private var viewModel = StudentHomeViewModel()
    @State private var isPickingDestination = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, \(session.user?.displayName ?? "there")")
                        .font(.title2.bold())
                    Text("Set where you're heading before you leave.")
                        .foregroundColor(.secondary)
                }

                if let destination = viewModel.destination {
                    DestinationCard(
                        destination: destination,
                        onChange: { isPickingDestination = true },
                        onClear: viewModel.clearDestination
                    )
                } else {
                    Button {
                        isPickingDestination = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Set Destination")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Search for where you're travelling to")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $isPickingDestination) {
            DestinationPickerView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        StudentHomeView(session: SessionViewModel())
            .navigationTitle("Student")
    }
}
