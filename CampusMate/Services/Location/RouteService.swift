import Foundation
import MapKit

struct RouteInfo {
    enum Kind {
        case walking
        case driving
        case transit
    }

    let polyline: MKPolyline
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let kind: Kind
}

final class RouteService {
    static let shared = RouteService()

    // Returns the shortest route Apple Maps can find for any transport type, or nil if there is none.
    func route(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> RouteInfo? {
        var candidates: [MKRoute] = []
        for transport: MKDirectionsTransportType in [.any, .walking, .automobile] {
            if let routes = try? await calculate(from: start, to: end, transport: transport), !routes.isEmpty {
                candidates.append(contentsOf: routes)
                break
            }
        }
        guard let shortest = candidates.min(by: { $0.distance < $1.distance }) else { return nil }
        return RouteInfo(polyline: shortest.polyline,
                         distance: shortest.distance,
                         expectedTravelTime: shortest.expectedTravelTime,
                         kind: kind(of: shortest.transportType))
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
