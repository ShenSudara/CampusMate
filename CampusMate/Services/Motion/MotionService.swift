import Foundation
import CoreMotion

// Watches the accelerometer and gyroscope for impacts, violent shaking or spinning.
final class MotionService {
    enum Event {
        case impact, shaking, spinning

        var description: String {
            switch self {
            case .impact: return "a hard impact"
            case .shaking: return "violent shaking"
            case .spinning: return "sudden tumbling"
            }
        }
    }

    static let shared = MotionService()

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private var shakeSamples: [Date] = []
    private var lastEventAt: Date?

    var onEvent: ((Event) -> Void)?

    var isAvailable: Bool { manager.isDeviceMotionAvailable }
    var isRunning: Bool { manager.isDeviceMotionActive }

    init() {
        queue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard isAvailable, !isRunning else { return }
        shakeSamples = []
        manager.deviceMotionUpdateInterval = 1 / SafetyThresholds.motionSampleRate
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.process(motion)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        shakeSamples = []
    }

    // Restarts the cooldown, e.g. after the student says they are OK.
    func resetCooldown() {
        lastEventAt = Date()
    }

    private func process(_ motion: CMDeviceMotion) {
        let now = Date()
        if let lastEventAt, now.timeIntervalSince(lastEventAt) < SafetyThresholds.motionCooldown { return }

        // userAcceleration already has gravity removed, so walking stays well below these values.
        let a = motion.userAcceleration
        let acceleration = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        let r = motion.rotationRate
        let rotation = (r.x * r.x + r.y * r.y + r.z * r.z).squareRoot()

        var event: Event?
        if acceleration >= SafetyThresholds.impactAcceleration {
            event = .impact
        } else if rotation >= SafetyThresholds.rotationRate {
            event = .spinning
        } else if acceleration >= SafetyThresholds.shakeAcceleration {
            shakeSamples.append(now)
            shakeSamples.removeAll { now.timeIntervalSince($0) > SafetyThresholds.shakeWindow }
            let neededSamples = Int(SafetyThresholds.shakeDuration * SafetyThresholds.motionSampleRate)
            if shakeSamples.count >= neededSamples {
                event = .shaking
            }
        }

        guard let event else { return }
        lastEventAt = now
        shakeSamples = []
        onEvent?(event)
    }
}
