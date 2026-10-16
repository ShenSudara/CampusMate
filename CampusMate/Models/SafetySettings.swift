import Foundation

// User-adjustable safety values. The defaults are used until the user saves their own.
struct SafetySettings: Equatable {
    var checkInResponseWindow: TimeInterval
    var impactAcceleration: Double
    var shakeAcceleration: Double
    var shakeDuration: TimeInterval
    var rotationRate: Double
    var motionResponseWindow: TimeInterval
    var motionCooldown: TimeInterval
    var sosHoldDuration: TimeInterval
    var sosResendDelay: TimeInterval

    static let defaults = SafetySettings(
        checkInResponseWindow: 5 * 60,
        impactAcceleration: 2.7,
        shakeAcceleration: 1.6,
        shakeDuration: 1.5,
        rotationRate: 12,
        motionResponseWindow: 30,
        motionCooldown: 60,
        sosHoldDuration: 1.5,
        sosResendDelay: 30
    )

    // Allowed ranges, so a typo can't switch a safety feature off.
    static let checkInResponseRange: ClosedRange<TimeInterval> = 60...(15 * 60)
    static let impactRange: ClosedRange<Double> = 1.5...5
    static let shakeRange: ClosedRange<Double> = 1...3
    static let shakeDurationRange: ClosedRange<TimeInterval> = 0.5...3
    static let rotationRange: ClosedRange<Double> = 6...20
    static let motionResponseRange: ClosedRange<TimeInterval> = 10...120
    static let motionCooldownRange: ClosedRange<TimeInterval> = 15...300
    static let sosHoldRange: ClosedRange<TimeInterval> = 0.5...3
    static let sosResendRange: ClosedRange<TimeInterval> = 10...120
}
