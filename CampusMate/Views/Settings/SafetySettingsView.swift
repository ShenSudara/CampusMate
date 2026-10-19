import SwiftUI

struct SafetySettingsView: View {
    @StateObject private var viewModel = SafetySettingsViewModel()
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section {
                stepper("Reply time", value: $viewModel.draft.checkInResponseWindow,
                        range: SafetySettings.checkInResponseRange, step: 60,
                        text: "\(Int(viewModel.draft.checkInResponseWindow / 60)) min")
            } header: {
                Text("Check-ins I Send")
            } footer: {
                Text("How long a student has to tap I'm Fine after you send a check-in, before it counts as missed.")
            }

            Section {
                slider("Impact strength", value: $viewModel.draft.impactAcceleration,
                       range: SafetySettings.impactRange, step: 0.1, unit: "g")
                slider("Shake strength", value: $viewModel.draft.shakeAcceleration,
                       range: SafetySettings.shakeRange, step: 0.1, unit: "g")
                slider("Shake length", value: $viewModel.draft.shakeDuration,
                       range: SafetySettings.shakeDurationRange, step: 0.1, unit: "s")
                slider("Spin speed", value: $viewModel.draft.rotationRate,
                       range: SafetySettings.rotationRange, step: 0.5, unit: "rad/s")
            } header: {
                Text("Motion Detection")
            } footer: {
                Text("Higher values need stronger movement, so there are fewer false alarms but real incidents may be missed.")
            }

            Section {
                stepper("Time to answer", value: $viewModel.draft.motionResponseWindow,
                        range: SafetySettings.motionResponseRange, step: 5,
                        text: "\(Int(viewModel.draft.motionResponseWindow)) s")
                stepper("Pause between prompts", value: $viewModel.draft.motionCooldown,
                        range: SafetySettings.motionCooldownRange, step: 15,
                        text: "\(Int(viewModel.draft.motionCooldown)) s")
            } header: {
                Text("\"Are You OK?\" Prompt")
            } footer: {
                Text("If you don't answer in time, your group is alerted with your location.")
            }

            Section {
                slider("Hold time", value: $viewModel.draft.sosHoldDuration,
                       range: SafetySettings.sosHoldRange, step: 0.5, unit: "s")
                stepper("Wait before resending", value: $viewModel.draft.sosResendDelay,
                        range: SafetySettings.sosResendRange, step: 10,
                        text: "\(Int(viewModel.draft.sosResendDelay)) s")
            } header: {
                Text("SOS Button")
            }

            if let message = viewModel.errorMessage {
                Section { Text(message).foregroundColor(.red) }
            } else if let message = viewModel.infoMessage {
                Section { Label(message, systemImage: "checkmark.circle").foregroundColor(.green) }
            }

            Section {
                Button("Reset to Defaults", role: .destructive) { confirmReset = true }
                    .disabled(!viewModel.hasCustomValues && viewModel.isDefault)
            } footer: {
                Text(viewModel.hasCustomValues
                     ? "You're using your own saved values on this device."
                     : "You're using the default values.")
            }
        }
        .navigationTitle("Safety Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: viewModel.save)
                    .disabled(!viewModel.hasChanges)
            }
            if viewModel.hasChanges {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", action: viewModel.discardChanges)
                }
            }
        }
        .navigationBarBackButtonHidden(viewModel.hasChanges)
        .onChange(of: viewModel.draft) { _ in viewModel.infoMessage = nil }
        .confirmationDialog("Reset safety settings?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset to Defaults", role: .destructive, action: viewModel.resetToDefaults)
        } message: {
            Text("Your saved values will be deleted and the default values will be used.")
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        step: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.1f") \(unit)")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(title)
                .accessibilityValue("\(String(format: "%.1f", value.wrappedValue)) \(unit)")
        }
    }

    private func stepper(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                         step: Double, text: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text(text)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SafetySettingsView()
    }
}
