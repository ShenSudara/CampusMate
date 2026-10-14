import SwiftUI

struct HomeView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var studentHomeViewModel: StudentHomeViewModel
    @ObservedObject var tripViewModel: TripViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    @ObservedObject var guardianViewModel: GuardianViewModel
    @ObservedObject var alertsViewModel: AlertsViewModel
    @State private var isShowingMyAlerts = false
    let onOpenDestination: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                switch session.mode {
                case .student:
                    StudentHomeView(session: session,
                                    viewModel: studentHomeViewModel,
                                    tripViewModel: tripViewModel,
                                    groupsViewModel: groupsViewModel,
                                    onOpenDestination: onOpenDestination)
                case .guardian:
                    GuardianHomeView(viewModel: guardianViewModel, currentUser: session.user)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationTitle(session.mode.title)
            .toolbar {
                if session.mode == .student {
                    Button {
                        isShowingMyAlerts = true
                    } label: {
                        Image(systemName: alertsViewModel.myAlerts.isEmpty ? "bell" : "bell.badge")
                    }
                    .accessibilityLabel("Alerts about me")
                }
            }
            .sheet(isPresented: $isShowingMyAlerts) {
                NavigationStack {
                    AlertsListView(viewModel: alertsViewModel, mode: .student)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { isShowingMyAlerts = false }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    HomeView(session: SessionViewModel(),
             studentHomeViewModel: StudentHomeViewModel(),
             tripViewModel: TripViewModel(),
             groupsViewModel: GroupsViewModel(),
             guardianViewModel: GuardianViewModel(),
             alertsViewModel: AlertsViewModel(),
             onOpenDestination: {})
}
