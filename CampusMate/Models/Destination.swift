import Foundation
import CoreLocation

struct Destination: Codable, Equatable, Identifiable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double

    var id: String { "\(latitude),\(longitude)" }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
