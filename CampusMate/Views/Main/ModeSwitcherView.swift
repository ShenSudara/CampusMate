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
            .accessibilityHint("Students share their journeys. Guardians watch students' journeys.")

            if isSaving {
                ProgressView()
                    .accessibilityLabel("Saving mode")
            }
        }
    }
}

#Preview {
    ModeSwitcherView(selection: .student, isSaving: false, onSelect: { _ in })
        .padding()
}
