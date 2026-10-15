import Foundation
import Combine
import CoreLocation

// Sends an immediate SOS alert to everyone following the student's active journey.
@MainActor
final class SOSViewModel: ObservableObject {
    @Published private(set) var isSending = false
    @Published private(set) var lastSentAt: Date?
    @Published private(set) var now = Date()
    @Published var errorMessage: String?

    private let alertService: AlertService
    private let locationService: LocationService
    private let notificationService: NotificationService
    private var clock: AnyCancellable?

    init(alertService: AlertService = .shared,
         locationService: LocationService = .shared,
         notificationService: NotificationService = .shared) {
        self.alertService = alertService
        self.locationService = locationService
        self.notificationService = notificationService
    }

    var secondsUntilAvailable: Int {
        guard let lastSentAt else { return 0 }
        let remaining = SafetyThresholds.sosResendDelay - now.timeIntervalSince(lastSentAt)
        return max(0, Int(remaining.rounded(.up)))
    }

    var canSend: Bool { !isSending && secondsUntilAvailable == 0 }

    func send(for trip: Trip?) async {
        guard let trip, let tripId = trip.id, canSend else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        let coordinate = locationService.lastLocation?.coordinate ?? trip.lastCoordinate
        let alert = SafetyAlert(
            type: .sos,
            studentId: trip.studentId,
            studentName: trip.studentName,
            tripId: tripId,
            memberIds: trip.memberIds,
            message: "\(trip.studentName) pressed SOS and needs help now.",
            createdAt: Date(),
            createdBy: trip.studentId,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        )
        do {
            try await alertService.createAlert(alert)
            lastSentAt = Date()
            now = Date()
            notificationService.vibrate()
            startClock()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    // A new journey starts with a clean SOS state.
    func reset() {
        lastSentAt = nil
        errorMessage = nil
        clock = nil
    }

    private func startClock() {
        clock = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                self.now = date
                if self.secondsUntilAvailable == 0 { self.clock = nil }
            }
    }
}
