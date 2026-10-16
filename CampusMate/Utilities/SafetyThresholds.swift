import Foundation

// Safety timing and sensitivity values in one place. Most can be changed in
// Profile → Safety Settings; the defaults live in SafetySettings.defaults.
enum SafetyThresholds {
    private static var settings: SafetySettings { SafetySettingsStore.shared.current }

    // How long a student has to tap "I'm Fine" after this user sends a check-in ping.
    static var checkInResponseWindow: TimeInterval { settings.checkInResponseWindow }

    // Motion sensors are sampled this many times per second during a journey.
    static let motionSampleRate: Double = 50
    // A single spike of user acceleration above this (in g) counts as a hard impact, e.g. a fall.
    static var impactAcceleration: Double { settings.impactAcceleration }
    // Acceleration above this (in g) counts as violent shaking...
    static var shakeAcceleration: Double { settings.shakeAcceleration }
    // ...when it keeps happening for at least this long within the window below.
    static var shakeDuration: TimeInterval { settings.shakeDuration }
    static let shakeWindow: TimeInterval = 3
    // Rotation faster than this (radians per second) counts as violent spinning or tumbling.
    static var rotationRate: Double { settings.rotationRate }
    // How long the student has to tap "I'm OK" before guardians are alerted.
    static var motionResponseWindow: TimeInterval { settings.motionResponseWindow }
    // After a detection, ignore new ones for this long so one event can't trigger repeatedly.
    static var motionCooldown: TimeInterval { settings.motionCooldown }

    // How long the SOS button must be held before the alert is sent.
    static var sosHoldDuration: TimeInterval { settings.sosHoldDuration }
    // Wait this long before another SOS can be sent, so a repeated press doesn't spam the group.
    static var sosResendDelay: TimeInterval { settings.sosResendDelay }
}
