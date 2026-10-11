import Foundation
import Combine
import MapKit

@MainActor
final class StudentHomeViewModel: ObservableObject {
    @Published var searchText = "" {
        didSet { searchService.updateQuery(searchText) }
    }
    @Published private(set) var suggestions: [PlaceSuggestion] = []
    @Published private(set) var destination: Destination?
    @Published private(set) var isResolving = false
    @Published var errorMessage: String?

    private let searchService: PlaceSearchService

    init(searchService: PlaceSearchService = PlaceSearchService()) {
        self.searchService = searchService
        searchService.onSuggestions = { [weak self] results in
            Task { @MainActor in self?.suggestions = results }
        }
        searchService.onError = { [weak self] error in
            Task { @MainActor in
                // MapKit reports "no results" as an error while typing; only show real failures.
                if (error as NSError).code != MKError.placemarkNotFound.rawValue {
                    self?.errorMessage = AppError.userMessage(for: error)
                }
            }
        }
    }

    func select(_ suggestion: PlaceSuggestion) async -> Bool {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }
        do {
            destination = try await searchService.resolve(suggestion)
            searchText = ""
            suggestions = []
            return true
        } catch {
            errorMessage = AppError.userMessage(for: error)
            return false
        }
    }

    func clearDestination() {
        destination = nil
    }
}
