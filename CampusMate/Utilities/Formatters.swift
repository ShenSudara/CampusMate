import Foundation
import CoreLocation

enum Formatters {
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    private static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    static func duration(_ interval: TimeInterval) -> String {
        if interval < 60 { return "Under 1 min" }
        return durationFormatter.string(from: interval) ?? "-"
    }

    static func distance(_ meters: CLLocationDistance) -> String {
        distanceFormatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }
}
