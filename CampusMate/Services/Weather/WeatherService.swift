import Foundation
import CoreLocation

// Fetches current weather from Open-Meteo (free, no API key).
final class WeatherService {
    static let shared = WeatherService()

    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let weather_code: Int
            let is_day: Int
        }
        let current: Current
    }

    private struct CacheEntry {
        let weather: DestinationWeather
        let fetchedAt: Date
    }

    // Weather changes slowly, so the same place is fetched at most every 15 minutes.
    private let cacheLifetime: TimeInterval = 15 * 60
    private var cache: [String: CacheEntry] = [:]
    private let lock = NSLock()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func currentWeather(at coordinate: CLLocationCoordinate2D) async throws -> DestinationWeather {
        // About 1 km precision, so nearby destinations share a cached result.
        let key = String(format: "%.2f,%.2f", coordinate.latitude, coordinate.longitude)
        if let cached = cachedWeather(for: key) { return cached }

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let current = try JSONDecoder().decode(Response.self, from: data).current
        let weather = DestinationWeather(temperature: current.temperature_2m,
                                         weatherCode: current.weather_code,
                                         isDay: current.is_day == 1)
        store(weather, for: key)
        return weather
    }

    private func cachedWeather(for key: String) -> DestinationWeather? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = cache[key], Date().timeIntervalSince(entry.fetchedAt) < cacheLifetime else { return nil }
        return entry.weather
    }

    private func store(_ weather: DestinationWeather, for key: String) {
        lock.lock()
        cache[key] = CacheEntry(weather: weather, fetchedAt: Date())
        lock.unlock()
    }
}
