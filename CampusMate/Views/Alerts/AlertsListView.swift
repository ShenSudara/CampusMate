import SwiftUI

struct AlertsListView: View {
    @ObservedObject var viewModel: AlertsViewModel
    let mode: UserMode

    private var alerts: [SafetyAlert] {
        mode == .guardian ? viewModel.guardianAlerts : viewModel.myAlerts
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading alerts…")
            } else if let errorMessage = viewModel.errorMessage, alerts.isEmpty {
                EmptyStateView(systemImage: "exclamationmark.triangle",
                               title: "Couldn't load alerts",
                               message: errorMessage)
            } else if alerts.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.shield",
                    title: "No alerts",
                    message: mode == .guardian
                        ? "You'll see missed check-ins and possible emergencies for students in your groups here."
                        : "Alerts your group receives about your journeys will appear here."
                )
            } else {
                List {
                    if mode == .guardian && viewModel.notificationsDenied {
                        Label("Notifications are off, so you'll only see new alerts when you open the app.",
                              systemImage: "bell.slash")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                    ForEach(alerts) { alert in
                        NavigationLink {
                            AlertDetailView(alert: alert)
                        } label: {
                            AlertRowView(alert: alert,
                                         isUnseen: mode == .guardian && alert.createdAt > viewModel.lastSeenAt)
                        }
                    }
                }
            }
        }
        .navigationTitle(mode == .guardian ? "Alerts" : "Alerts About Me")
    }
}

#Preview {
    NavigationStack {
        AlertsListView(viewModel: AlertsViewModel(), mode: .guardian)
    }
}
