import Foundation

// Safety timing and sensitivity values, kept together so they are easy to tune.
enum SafetyThresholds {
    // How long a student has to tap "I'm Fine" after a guardian's check-in ping.
    static let checkInResponseWindow: TimeInterval = 5 * 60
}
