import Foundation
import Combine
import FirebaseFirestore

// Student side: shows incoming check-in pings and sends the "I'm Fine" reply.
@MainActor
final class CheckInViewModel: ObservableObject {
    @Published private(set) var activePing: CheckInPing?
    @Published private(set) var now = Date()
    @Published private(set) var isResponding = false
    @Published var errorMessage: String?

    private let pingService: PingService
    private let notificationService: NotificationService
    private var notifiedPingIds = Set<String>()
    private var listener: ListenerRegistration?
    private var pings: [CheckInPing] = []
    private var dismissedIds = Set<String>()
    private var clock: AnyCancellable?

    // An unanswered ping keeps showing for this long after its deadline, e.g. if the app is reopened.
    private let expiredPromptLifetime: TimeInterval = 5 * 60

    init(pingService: PingService = .shared, notificationService: NotificationService = .shared) {
        self.pingService = pingService
        self.notificationService = notificationService
    }

    var secondsLeft: Int { activePing?.secondsLeft(at: now) ?? 0 }

    var isExpired: Bool { activePing?.isExpired(at: now) ?? false }

    // Uses the ping's own window, since the guardian who sent it may use a different setting.
    var progress: Double {
        guard let ping = activePing else { return 0 }
        let window = ping.deadline.timeIntervalSince(ping.sentAt)
        return window > 0 ? Double(secondsLeft) / window : 0
    }

    func start(uid: String) {
        guard listener == nil else { return }
        listener = pingService.listenToPingsForStudent(uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let pings):
                    self.pings = pings
                    self.refresh()
                case .failure(let error):
                    self.errorMessage = AppError.userMessage(for: error)
                }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        clock = nil
        pings = []
        activePing = nil
    }

    func respondImFine() async {
        guard let pingId = activePing?.id else { return }
        isResponding = true
        errorMessage = nil
        defer { isResponding = false }
        do {
            try await pingService.acknowledge(pingId: pingId)
            dismissedIds.insert(pingId)
            refresh()
        } catch {
            errorMessage = AppError.userMessage(for: error)
        }
    }

    // Closes the prompt after the countdown ran out.
    func dismissExpired() {
        if let id = activePing?.id {
            dismissedIds.insert(id)
        }
        refresh()
    }

    private func refresh() {
        let current = Date()
        activePing = pings.first { ping in
            guard let id = ping.id, !dismissedIds.contains(id), ping.status == .pending else { return false }
            return current.timeIntervalSince(ping.deadline) < expiredPromptLifetime
        }
        now = current
        // Also notify, so the student is alerted when the app is in the background.
        if let ping = activePing, let id = ping.id, !ping.isExpired(at: current), !notifiedPingIds.contains(id) {
            notifiedPingIds.insert(id)
            notificationService.notify(id: "ping-\(id)",
                                       title: "\(ping.senderName) is checking on you",
                                       body: "Open CampusMate and tap I'm Fine within \(Formatters.countdown(ping.secondsLeft(at: current))) minutes.")
        }
        if activePing == nil {
            clock = nil
        } else if clock == nil {
            clock = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] date in self?.now = date }
        }
    }
}
