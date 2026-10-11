import SwiftUI
import MapKit

struct DestinationCard: View {
    let destination: Destination
    let onChange: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: destination.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))),
                interactionModes: [],
                annotationItems: [destination]) { place in
                MapMarker(coordinate: place.coordinate, tint: .red)
            }
            .frame(height: 150)
            .allowsHitTesting(false)

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
                Menu {
                    Button("Change Destination", systemImage: "pencil", action: onChange)
                    Button("Remove", systemImage: "xmark", role: .destructive, action: onClear)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .accessibilityLabel("Destination options")
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    DestinationCard(
        destination: Destination(name: "NIBM Colombo", address: "120/5 Wijerama Mawatha, Colombo 07",
                                 latitude: 6.9063, longitude: 79.8706),
        onChange: {},
        onClear: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
