import Foundation
import FirebaseFirestore
import CoreLocation

struct LocationPoint: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var latitude: Double
    var longitude: Double
    var speed: Double?
    var accuracy: Double
    var timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension LocationPoint {
    init(location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed >= 0 ? location.speed : nil,
            accuracy: location.horizontalAccuracy,
            timestamp: location.timestamp
        )
    }
}
