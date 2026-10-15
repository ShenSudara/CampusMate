import Foundation
import Combine
import CoreLocation

// Runs motion detection during the student's active trip and asks "Are you OK?" before alerting guardians.
@MainActor
final class SafetyMonitorViewModel: ObservableObject {
    struct Prompt: Equatable {
        let reason: String
        let deadline: Date
    }

    @Published private(set) var prompt: Prompt?
    @Published private(set) var now = Date()
    @Published private(set) var isSending = false
    @Published private(set) var alertSent = false
    @Published var errorMessage: String?

    private let motionService: MotionService
    private let alertService: AlertService
    private let locationService: LocationService
    private let notificationService: NotificationService
    private var trip: Trip?
    private var clock: AnyCancellable?

    init(motionService: MotionService = .shared,
         alertService: AlertService = .shared,
         locationService: LocationService = .shared,
         notificationService: NotificationService = .shared) {
        self.motionService = motionService
        self.alertService = alertService
        self.locationService = locationService
        self.notificationService = notificationService
        motionService.onEvent = { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
    }

    var secondsLeft: Int {
        guard let prompt else { return 0 }
        return max(0, Int(prompt.deadline.timeIntervalSince(now).rounded(.up)))
    }

    var progress: Double {
        Double(secondsLeft) / SafetyThresholds.motionResponseWindow
    }

    // Called whenever the active trip changes; monitoring runs only during a trip.
    func update(trip: Trip?) {
        self.trip = trip
        if trip != nil {
            motionService.start()
        } else {
            motionService.stop()
            clearPrompt()
        }
    }

    func stop() {
        update(trip: nil)
    }

    func confirmOK() {
        motionService.resetCooldown()
        clearPrompt()
    }

    func sendAlertNow() async {
        await sendAlert()
    }

    func dismissSent() {
        clearPrompt()
    }

    private func handle(_ event: MotionService.Event) {
        guard trip != nil, prompt == nil else { return }
        let reason = "We detected \(event.description)."
        prompt = Prompt(reason: reason,
                        deadline: Date().addingTimeInterval(SafetyThresholds.motionResponseWindow))
        alertSent = false
        errorMessage = nil
        now = Date()
        notificationService.vibrate()
        notificationService.notify(id: "motion-\(Int(Date().timeIntervalSince1970))",
                                   title: "Are you OK?",
                                   body: "\(reason) Open CampusMate and tap I'm OK, or your group will be alerted.")
        clock = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.tick(date) }
    }

    private func tick(_ date: Date) {
        now = date
        guard let prompt, !alertSent, !isSending else { return }
        if date >= prompt.deadline {
            Task { await sendAlert() }
        } else {
            notificationService.vibrate()
        }
    }

    private func sendAlert() async {
        guard let trip, let tripId = trip.id, let prompt, !alertSent, !isSending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        let coordinate = locationService.lastLocation?.coordinate ?? trip.lastCoordinate
        let alert = SafetyAlert(
            type: .motionDetected,
            studentId: trip.studentId,
            studentName: trip.studentName,
            tripId: tripId,
            memberIds: trip.memberIds,
            message: "\(prompt.reason) \(trip.studentName) didn't confirm they're OK.",
            createdAt: Date(),
            createdBy: trip.studentId,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        )
        do {
            try await alertService.createAlert(alert)
            alertSent = true
            clock = nil
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    private func clearPrompt() {
        prompt = nil
        alertSent = false
        errorMessage = nil
        clock = nil
    }
}
