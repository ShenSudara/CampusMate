import Foundation
import Combine

@MainActor
final class SafetySettingsViewModel: ObservableObject {
    @Published var draft: SafetySettings
    @Published private(set) var saved: SafetySettings
    @Published private(set) var hasCustomValues: Bool
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let store: SafetySettingsStore

    init(store: SafetySettingsStore = .shared) {
        self.store = store
        draft = store.current
        saved = store.current
        hasCustomValues = store.hasCustomValues
    }

    var hasChanges: Bool { draft != saved }
    var isDefault: Bool { draft == .defaults }

    func load() {
        store.reload()
        draft = store.current
        saved = store.current
        hasCustomValues = store.hasCustomValues
    }

    func save() {
        errorMessage = nil
        do {
            try store.save(draft)
            saved = draft
            hasCustomValues = true
            infoMessage = "Settings saved."
        } catch {
            errorMessage = "Couldn't save your settings. Please try again."
        }
    }

    func discardChanges() {
        draft = saved
        infoMessage = nil
    }

    func resetToDefaults() {
        errorMessage = nil
        do {
            try store.reset()
            draft = .defaults
            saved = .defaults
            hasCustomValues = false
            infoMessage = "Default settings restored."
        } catch {
            errorMessage = "Couldn't reset your settings. Please try again."
        }
    }
}
