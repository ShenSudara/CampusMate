import Foundation
import CoreData

// Loads and saves the user's safety settings in Core Data and keeps the current values in memory.
final class SafetySettingsStore {
    static let shared = SafetySettingsStore()

    private let persistence: PersistenceController
    private let lock = NSLock()
    private var cached: SafetySettings = .defaults
    private(set) var hasCustomValues = false

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        reload()
    }

    // Read from the motion sensor queue as well as the main thread, so access is locked.
    var current: SafetySettings {
        lock.lock()
        defer { lock.unlock() }
        return cached
    }

    func reload() {
        let context = persistence.viewContext
        context.performAndWait {
            if let entity = try? context.fetch(Self.fetchRequest()).first {
                setCached(Self.settings(from: entity), custom: true)
            } else {
                setCached(.defaults, custom: false)
            }
        }
    }

    func save(_ settings: SafetySettings) throws {
        if let error = persistence.loadError { throw error }
        let context = persistence.viewContext
        try context.performAndWait {
            let entity = try context.fetch(Self.fetchRequest()).first ?? SafetySettingsEntity(context: context)
            entity.checkInResponseWindow = settings.checkInResponseWindow
            entity.impactAcceleration = settings.impactAcceleration
            entity.shakeAcceleration = settings.shakeAcceleration
            entity.shakeDuration = settings.shakeDuration
            entity.rotationRate = settings.rotationRate
            entity.motionResponseWindow = settings.motionResponseWindow
            entity.motionCooldown = settings.motionCooldown
            entity.sosHoldDuration = settings.sosHoldDuration
            entity.sosResendDelay = settings.sosResendDelay
            entity.updatedAt = Date()
            try context.save()
        }
        setCached(settings, custom: true)
    }

    // Deletes the saved values so the defaults apply again.
    func reset() throws {
        if let error = persistence.loadError { throw error }
        let context = persistence.viewContext
        try context.performAndWait {
            for entity in try context.fetch(Self.fetchRequest()) {
                context.delete(entity)
            }
            try context.save()
        }
        setCached(.defaults, custom: false)
    }

    private func setCached(_ settings: SafetySettings, custom: Bool) {
        lock.lock()
        cached = settings
        hasCustomValues = custom
        lock.unlock()
    }

    private static func fetchRequest() -> NSFetchRequest<SafetySettingsEntity> {
        let request = NSFetchRequest<SafetySettingsEntity>(entityName: "SafetySettingsEntity")
        request.fetchLimit = 1
        return request
    }

    private static func settings(from entity: SafetySettingsEntity) -> SafetySettings {
        SafetySettings(
            checkInResponseWindow: entity.checkInResponseWindow,
            impactAcceleration: entity.impactAcceleration,
            shakeAcceleration: entity.shakeAcceleration,
            shakeDuration: entity.shakeDuration,
            rotationRate: entity.rotationRate,
            motionResponseWindow: entity.motionResponseWindow,
            motionCooldown: entity.motionCooldown,
            sosHoldDuration: entity.sosHoldDuration,
            sosResendDelay: entity.sosResendDelay
        )
    }
}
