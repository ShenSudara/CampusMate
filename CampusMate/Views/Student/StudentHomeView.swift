import SwiftUI

struct StudentHomeView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var viewModel: StudentHomeViewModel
    let onOpenDestination: () -> Void

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
                        onChange: onOpenDestination,
                        onClear: viewModel.clearDestination
                    )
                } else {
                    Button(action: onOpenDestination) {
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
    }
}

#Preview {
    NavigationStack {
        StudentHomeView(session: SessionViewModel(), viewModel: StudentHomeViewModel(), onOpenDestination: {})
            .navigationTitle("Student")
    }
}
