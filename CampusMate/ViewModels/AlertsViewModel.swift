import Foundation
import Combine
import UserNotifications
import FirebaseFirestore

// Keeps the user's safety alerts up to date and notifies them about new ones.
@MainActor
final class AlertsViewModel: ObservableObject {
    @Published private(set) var alerts: [SafetyAlert] = []
    @Published private(set) var isLoading = true
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published private(set) var lastSeenAt: Date = .distantPast

    private let alertService: AlertService
    private let notificationService: NotificationService
    private var listener: ListenerRegistration?
    private var uid: String?

    // Alerts older than this are not notified, e.g. when the app opens after a long time.
    private let notifyWindow: TimeInterval = 30 * 60
    private let notifiedKey = "notifiedAlertIds"
    private var lastSeenKey: String { "alertsLastSeenAt-\(uid ?? "")" }

    init(alertService: AlertService = .shared, notificationService: NotificationService = .shared) {
        self.alertService = alertService
        self.notificationService = notificationService
    }

    var notificationsDenied: Bool { notificationStatus == .denied }

    // Guardian view: alerts about other members.
    var guardianAlerts: [SafetyAlert] { alerts.filter { $0.studentId != uid } }

    // Student view: alerts the group received about this user.
    var myAlerts: [SafetyAlert] { alerts.filter { $0.studentId == uid } }

    var unseenCount: Int { guardianAlerts.filter { $0.createdAt > lastSeenAt }.count }

    func markAllSeen() {
        lastSeenAt = Date()
        UserDefaults.standard.set(lastSeenAt, forKey: lastSeenKey)
    }

    func start(uid: String) {
        guard listener == nil else { return }
        self.uid = uid
        lastSeenAt = UserDefaults.standard.object(forKey: lastSeenKey) as? Date ?? .distantPast
        Task { await refreshNotificationStatus() }
        listener = alertService.listenToAlertsVisible(to: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let alerts):
                    self.alerts = alerts
                    self.notifyAboutNew(alerts)
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
                self.isLoading = false
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        alerts = []
        isLoading = true
    }

    func requestNotificationPermission() async {
        await notificationService.requestAuthorization()
        await refreshNotificationStatus()
    }

    func refreshNotificationStatus() async {
        notificationStatus = await notificationService.authorizationStatus()
        if notificationStatus == .notDetermined {
            await notificationService.requestAuthorization()
            notificationStatus = await notificationService.authorizationStatus()
        }
    }

    // Alerts about the user themselves (as a student) are not notified to them.
    private func notifyAboutNew(_ alerts: [SafetyAlert]) {
        guard let uid else { return }
        var notified = Set(UserDefaults.standard.stringArray(forKey: notifiedKey) ?? [])
        let cutoff = Date().addingTimeInterval(-notifyWindow)
        for alert in alerts where alert.studentId != uid && alert.createdAt > cutoff {
            guard let id = alert.id, !notified.contains(id) else { continue }
            notified.insert(id)
            notificationService.notify(id: "alert-\(id)",
                                       title: "\(alert.type == .sos ? "🆘" : "⚠️") \(alert.type.title): \(alert.studentName)",
                                       body: alert.message)
        }
        // Keep the stored list small; only recent alerts can be notified anyway.
        let recentIds = Set(alerts.filter { $0.createdAt > cutoff }.compactMap(\.id))
        UserDefaults.standard.set(Array(notified.intersection(recentIds)), forKey: notifiedKey)
    }
}
