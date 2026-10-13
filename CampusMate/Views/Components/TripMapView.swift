import SwiftUI
import MapKit

// MKMapView wrapper used for the guardian live map: student pin, destination pin and travelled path.
struct TripMapView: UIViewRepresentable {
    let studentName: String?
    let studentCoordinate: CLLocationCoordinate2D?
    let isStale: Bool
    let destination: Destination?
    let path: [CLLocationCoordinate2D]
    // Changing this re-fits the map, e.g. when another student is selected.
    let focusKey: String?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.showsCompass = true
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.isStale = isStale

        mapView.removeOverlays(mapView.overlays)
        if path.count > 1 {
            mapView.addOverlay(MKPolyline(coordinates: path, count: path.count))
        }

        mapView.removeAnnotations(mapView.annotations)
        var annotations: [MKAnnotation] = []
        if let destination {
            let pin = DestinationAnnotation()
            pin.coordinate = destination.coordinate
            pin.title = destination.name
            annotations.append(pin)
        }
        if let studentCoordinate {
            let pin = StudentAnnotation()
            pin.coordinate = studentCoordinate
            pin.title = studentName
            annotations.append(pin)
        }
        mapView.addAnnotations(annotations)

        if coordinator.lastFocusKey != focusKey || (!coordinator.hasFitted && !annotations.isEmpty) {
            coordinator.lastFocusKey = focusKey
            coordinator.hasFitted = !annotations.isEmpty
            let coordinates = annotations.map(\.coordinate) + path
            if let region = MKCoordinateRegion.fitting(coordinates) {
                mapView.setRegion(region, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class StudentAnnotation: MKPointAnnotation {}
    final class DestinationAnnotation: MKPointAnnotation {}

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastFocusKey: String?
        var hasFitted = false
        var isStale = false

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8)
            renderer.lineWidth = 5
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is StudentAnnotation {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "student")
                view.glyphImage = UIImage(systemName: "figure.walk")
                view.markerTintColor = isStale ? .systemOrange : .systemBlue
                view.displayPriority = .required
                view.canShowCallout = true
                return view
            }
            if annotation is DestinationAnnotation {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "destination")
                view.glyphImage = UIImage(systemName: "flag.checkered")
                view.markerTintColor = .systemRed
                view.displayPriority = .required
                view.canShowCallout = true
                return view
            }
            return nil
        }
    }
}

#Preview {
    TripMapView(
        studentName: "Alex Perera",
        studentCoordinate: CLLocationCoordinate2D(latitude: 6.9200, longitude: 79.8650),
        isStale: false,
        destination: Destination(name: "NIBM Colombo", address: "Colombo 07", latitude: 6.9063, longitude: 79.8706),
        path: [
            CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            CLLocationCoordinate2D(latitude: 6.9240, longitude: 79.8630),
            CLLocationCoordinate2D(latitude: 6.9200, longitude: 79.8650)
        ],
        focusKey: "alex"
    )
}
