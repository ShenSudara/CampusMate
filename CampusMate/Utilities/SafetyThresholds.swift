import Foundation

// Safety timing and sensitivity values, kept together so they are easy to tune.
enum SafetyThresholds {
    // How long a student has to tap "I'm Fine" after a guardian's check-in ping.
    static let checkInResponseWindow: TimeInterval = 5 * 60

    // Motion sensors are sampled this many times per second during a journey.
    static let motionSampleRate: Double = 50
    // A single spike of user acceleration above this (in g) counts as a hard impact, e.g. a fall.
    static let impactAcceleration: Double = 2.7
    // Acceleration above this (in g) counts as violent shaking...
    static let shakeAcceleration: Double = 1.6
    // ...when it keeps happening for at least this long within the window below.
    static let shakeDuration: TimeInterval = 1.5
    static let shakeWindow: TimeInterval = 3
    // Rotation faster than this (radians per second) counts as violent spinning or tumbling.
    static let rotationRate: Double = 12
    // How long the student has to tap "I'm OK" before guardians are alerted.
    static let motionResponseWindow: TimeInterval = 30
    // After a detection, ignore new ones for this long so one event can't trigger repeatedly.
    static let motionCooldown: TimeInterval = 60
}
