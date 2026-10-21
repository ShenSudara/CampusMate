import SwiftUI

// One-line current weather at a destination, e.g. "27° · Cloudy".
struct DestinationWeatherView: View {
    let destination: Destination
    @StateObject private var viewModel = DestinationWeatherViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking weather…")
                }
                .foregroundColor(.secondary)
            case .loaded(let weather):
                Label {
                    Text(weather.temperatureText).bold() + Text(" · \(weather.summary)")
                } icon: {
                    Image(systemName: weather.systemImage)
                        .symbolRenderingMode(.multicolor)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weather at destination: \(weather.temperatureText), \(weather.summary)")
            case .unavailable:
                Label("Weather unavailable", systemImage: "cloud.slash")
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .task(id: destination) {
            await viewModel.load(for: destination)
        }
    }
}

#Preview {
    DestinationWeatherView(destination: Destination(name: "NIBM Colombo", address: "Colombo 07",
                                                    latitude: 6.9063, longitude: 79.8706))
        .padding()
}
