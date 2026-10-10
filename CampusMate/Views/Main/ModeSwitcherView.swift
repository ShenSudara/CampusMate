import SwiftUI

struct ModeSwitcherView: View {
    let selection: UserMode
    let isSaving: Bool
    let onSelect: (UserMode) -> Void

    var body: some View {
        HStack {
            Picker("Mode", selection: Binding(get: { selection }, set: onSelect)) {
                ForEach(UserMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isSaving)

            if isSaving {
                ProgressView()
            }
        }
    }
}
