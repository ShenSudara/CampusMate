import Foundation
import Combine
import CoreLocation

@MainActor
final class DestinationWeatherViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded(DestinationWeather)
        case unavailable
    }

    @Published private(set) var state: State = .loading

    private let weatherService: WeatherService

    init(weatherService: WeatherService = .shared) {
        self.weatherService = weatherService
    }

    func load(for destination: Destination) async {
        state = .loading
        do {
            let weather = try await weatherService.currentWeather(at: destination.coordinate)
            state = .loaded(weather)
        } catch is CancellationError {
            // The destination changed before the request finished; the new load takes over.
        } catch {
            state = .unavailable
        }
    }
}
