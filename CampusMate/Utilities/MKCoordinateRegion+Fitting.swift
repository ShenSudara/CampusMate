import MapKit

extension MKCoordinateRegion {
    // A region that shows all coordinates with some padding around them.
    static func fitting(_ coordinates: [CLLocationCoordinate2D],
                        minimumSpan: CLLocationDegrees = 0.01) -> MKCoordinateRegion? {
        guard let first = coordinates.first else { return nil }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.5, minimumSpan),
                                   longitudeDelta: max((maxLon - minLon) * 1.5, minimumSpan))
        )
    }
}
