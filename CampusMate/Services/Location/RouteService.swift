import Foundation
import MapKit

struct RouteInfo {
    let polyline: MKPolyline
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let transportType: MKDirectionsTransportType
}

final class RouteService {
    static let shared = RouteService()

    // Walking is preferred; driving is used when no walking route exists (e.g. very long trips).
    func route(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> RouteInfo {
        do {
            return try await calculate(from: start, to: end, transport: .walking)
        } catch {
            return try await calculate(from: start, to: end, transport: .automobile)
        }
    }

    private func calculate(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D,
                           transport: MKDirectionsTransportType) async throws -> RouteInfo {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = transport
        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw AppError.message("No route found to this destination.")
        }
        return RouteInfo(polyline: route.polyline,
                         distance: route.distance,
                         expectedTravelTime: route.expectedTravelTime,
                         transportType: transport)
    }
}
