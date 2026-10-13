import SwiftUI
import MapKit

// MKMapView wrapper for the student's Destination tab: user location, destination pin and suggested route.
struct RoutePlanningMapView: UIViewRepresentable {
    let region: MKCoordinateRegion
    // The map only moves when this changes, so the user can pan freely in between.
    let regionChangeId: Int
    let destination: Destination?
    let routePolyline: MKPolyline?
    var onTap: () -> Void = {}

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.setRegion(region, animated: false)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onTap = onTap

        if coordinator.appliedRegionChangeId != regionChangeId {
            coordinator.appliedRegionChangeId = regionChangeId
            mapView.setRegion(region, animated: true)
        }

        if coordinator.shownPolyline !== routePolyline {
            mapView.removeOverlays(mapView.overlays)
            if let routePolyline {
                mapView.addOverlay(routePolyline, level: .aboveRoads)
            }
            coordinator.shownPolyline = routePolyline
        }

        if coordinator.shownDestination != destination {
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            if let destination {
                let pin = MKPointAnnotation()
                pin.coordinate = destination.coordinate
                pin.title = destination.name
                mapView.addAnnotation(pin)
            }
            coordinator.shownDestination = destination
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var appliedRegionChangeId = -1
        var shownPolyline: MKPolyline?
        var shownDestination: Destination?
        var onTap: () -> Void = {}

        @objc func handleTap() { onTap() }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemPurple
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            // A direct line (only two points) is dashed so it isn't mistaken for a road route.
            if polyline.pointCount == 2 {
                renderer.lineDashPattern = [8, 8]
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "destination")
            view.glyphImage = UIImage(systemName: "flag.checkered")
            view.markerTintColor = .systemRed
            view.displayPriority = .required
            view.canShowCallout = true
            return view
        }
    }
}

#Preview {
    RoutePlanningMapView(
        region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 6.9167, longitude: 79.866),
                                   span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)),
        regionChangeId: 0,
        destination: Destination(name: "NIBM Colombo", address: "Colombo 07", latitude: 6.9063, longitude: 79.8706),
        routePolyline: MKPolyline(coordinates: [
            CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            CLLocationCoordinate2D(latitude: 6.9150, longitude: 79.8650),
            CLLocationCoordinate2D(latitude: 6.9063, longitude: 79.8706)
        ], count: 3)
    )
}
