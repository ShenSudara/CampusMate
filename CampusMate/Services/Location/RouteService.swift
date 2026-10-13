import Foundation
import MapKit

struct RouteInfo {
    enum Kind {
        case walking
        case driving
        case transit
        // Straight line, used when Apple Maps has no directions for the area.
        case direct
    }

    let polyline: MKPolyline
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval?
    let kind: Kind
}

final class RouteService {
    static let shared = RouteService()

    // Returns the shortest route Apple Maps can find for any transport type,
    // or a direct line when no directions are available.
    func route(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> RouteInfo {
        var candidates: [MKRoute] = []
        for transport: MKDirectionsTransportType in [.any, .walking, .automobile] {
            if let routes = try? await calculate(from: start, to: end, transport: transport), !routes.isEmpty {
                candidates.append(contentsOf: routes)
                break
            }
        }
        if let shortest = candidates.min(by: { $0.distance < $1.distance }) {
            return RouteInfo(polyline: shortest.polyline,
                             distance: shortest.distance,
                             expectedTravelTime: shortest.expectedTravelTime,
                             kind: kind(of: shortest.transportType))
        }
        var coordinates = [start, end]
        let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
        return RouteInfo(polyline: MKPolyline(coordinates: &coordinates, count: 2),
                         distance: distance,
                         expectedTravelTime: nil,
                         kind: .direct)
    }

    private func calculate(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D,
                           transport: MKDirectionsTransportType) async throws -> [MKRoute] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transport
        request.requestsAlternateRoutes = true
        return try await MKDirections(request: request).calculate().routes
    }

    private func kind(of transport: MKDirectionsTransportType) -> RouteInfo.Kind {
        if transport.contains(.walking) { return .walking }
        if transport.contains(.transit) { return .transit }
        return .driving
    }
}
