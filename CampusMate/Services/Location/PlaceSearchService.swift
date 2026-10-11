import Foundation
import MapKit

struct PlaceSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    fileprivate let completion: MKLocalSearchCompletion

    static func == (lhs: PlaceSuggestion, rhs: PlaceSuggestion) -> Bool { lhs.id == rhs.id }
}

// Wraps MKLocalSearchCompleter for type-ahead suggestions and resolves a suggestion to coordinates.
final class PlaceSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    var onSuggestions: (([PlaceSuggestion]) -> Void)?
    var onError: ((Error) -> Void)?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            completer.cancel()
            onSuggestions?([])
        } else {
            completer.queryFragment = query
        }
    }

    func setSearchRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func resolve(_ suggestion: PlaceSuggestion) async throws -> Destination {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw AppError.message("Could not find that place. Try another search.")
        }
        let coordinate = item.placemark.coordinate
        return Destination(
            name: item.name ?? suggestion.title,
            address: suggestion.subtitle.isEmpty ? (item.placemark.title ?? "") : suggestion.subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onSuggestions?(completer.results.map {
            PlaceSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0)
        })
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onError?(error)
    }
}
