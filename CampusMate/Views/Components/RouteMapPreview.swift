import SwiftUI
import MapKit

// A small, non-interactive map showing the user's position and the destination pin.
struct RouteMapPreview: View {
    let destination: Destination
    let userCoordinate: CLLocationCoordinate2D?
    var height: CGFloat = 150

    private var region: MKCoordinateRegion {
        MKCoordinateRegion.fitting([destination.coordinate] + [userCoordinate].compactMap { $0 })
            ?? MKCoordinateRegion(center: destination.coordinate,
                                  span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }

    var body: some View {
        Map(coordinateRegion: .constant(region),
            interactionModes: [],
            showsUserLocation: true,
            annotationItems: [destination]) { place in
            MapMarker(coordinate: place.coordinate, tint: .red)
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

#Preview {
    RouteMapPreview(
        destination: Destination(name: "NIBM Colombo", address: "Colombo 07", latitude: 6.9063, longitude: 79.8706),
        userCoordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    )
}
