import SwiftUI

struct MainTabView: View {
    enum Tab {
        case home, destination, history, alerts, groups, profile
    }

    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var session = SessionViewModel()
    @StateObject private var groupsViewModel = GroupsViewModel()
    @StateObject private var studentHomeViewModel = StudentHomeViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var guardianViewModel = GuardianViewModel()
    @StateObject private var historyViewModel = TripHistoryViewModel()
    @StateObject private var checkInViewModel = CheckInViewModel()
    @StateObject private var alertsViewModel = AlertsViewModel()
    @StateObject private var safetyMonitor = SafetyMonitorViewModel()
    @StateObject private var sosViewModel = SOSViewModel()
    @State private var selectedTab: Tab = .home

    var body: some View {
        Group {
            if session.isLoading && session.user == nil {
                if let errorMessage = session.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Try Again") { Task { await session.retry() } }
                            .buttonStyle(.borderedProminent)
                        Button("Sign Out", role: .destructive, action: authViewModel.signOut)
                    }
                    .padding()
                } else {
                    ProgressView("Loading your profile…")
                }
            } else {
                TabView(selection: $selectedTab) {
                    HomeView(session: session,
                             studentHomeViewModel: studentHomeViewModel,
                             tripViewModel: tripViewModel,
                             groupsViewModel: groupsViewModel,
                             guardianViewModel: guardianViewModel,
                             alertsViewModel: alertsViewModel,
                             sosViewModel: sosViewModel,
                             onOpenDestination: { selectedTab = .destination })
                        .tabItem { Label("Home", systemImage: session.mode.systemImage) }
                        .tag(Tab.home)
                    if session.mode == .student {
                        DestinationMapView(viewModel: studentHomeViewModel,
                                           tripViewModel: tripViewModel,
                                           groupsViewModel: groupsViewModel,
                                           session: session,
                                           sosViewModel: sosViewModel)
                            .tabItem { Label("Destination", systemImage: "map") }
                            .tag(Tab.destination)
                    }
                    TripHistoryView(viewModel: historyViewModel, mode: session.mode)
                        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                        .tag(Tab.history)
                    if session.mode == .guardian {
                        NavigationStack {
                            AlertsListView(viewModel: alertsViewModel, mode: .guardian)
                        }
                        .tabItem { Label("Alerts", systemImage: "bell.fill") }
                        .badge(alertsViewModel.unseenCount)
                        .tag(Tab.alerts)
                        .onDisappear(perform: alertsViewModel.markAllSeen)
                    }
                    GroupListView(viewModel: groupsViewModel, session: session)
                        .tabItem { Label("Groups", systemImage: "person.3") }
                        .tag(Tab.groups)
                    ProfileView(session: session, authViewModel: authViewModel, alertsViewModel: alertsViewModel)
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(Tab.profile)
                }
                .onChange(of: session.mode) { mode in
                    if (mode == .guardian && selectedTab == .destination)
                        || (mode == .student && selectedTab == .alerts) {
                        selectedTab = .home
                    }
                }
            }
        }
        .fullScreenCover(isPresented: Binding(get: { safetyMonitor.prompt != nil }, set: { _ in })) {
            AreYouOKView(
                reason: safetyMonitor.prompt?.reason ?? "",
                secondsLeft: safetyMonitor.secondsLeft,
                progress: safetyMonitor.progress,
                isSending: safetyMonitor.isSending,
                alertSent: safetyMonitor.alertSent,
                errorMessage: safetyMonitor.errorMessage,
                onImOK: safetyMonitor.confirmOK,
                onSendNow: { Task { await safetyMonitor.sendAlertNow() } },
                onClose: safetyMonitor.dismissSent
            )
        }
        .alert("You've arrived",
               isPresented: Binding(get: { tripViewModel.arrivedAt != nil }, set: { _ in })) {
            Button("End Journey") { Task { await tripViewModel.confirmArrival() } }
            Button("Not Yet", role: .cancel, action: tripViewModel.declineArrival)
        } message: {
            Text("You're at \(tripViewModel.arrivedAt?.name ?? "your destination"). End your journey and let your group know you arrived safely?")
        }
        .onChange(of: tripViewModel.activeTrip?.id) { _ in
            safetyMonitor.update(trip: tripViewModel.activeTrip)
            sosViewModel.reset()
        }
        .fullScreenCover(isPresented: Binding(get: { checkInViewModel.activePing != nil }, set: { _ in })) {
            CheckInPromptView(
                senderName: checkInViewModel.activePing?.senderName ?? "Your guardian",
                secondsLeft: checkInViewModel.secondsLeft,
                progress: checkInViewModel.progress,
                isExpired: checkInViewModel.isExpired,
                isResponding: checkInViewModel.isResponding,
                errorMessage: checkInViewModel.errorMessage,
                onImFine: { Task { await checkInViewModel.respondImFine() } },
                onDismiss: checkInViewModel.dismissExpired
            )
        }
        .onDisappear {
            groupsViewModel.stop()
            sosViewModel.reset()
            tripViewModel.stop()
            guardianViewModel.stop()
            historyViewModel.stop()
            checkInViewModel.stop()
            alertsViewModel.stop()
            safetyMonitor.stop()
            studentHomeViewModel.stopFollowingLocation()
        }
        .task {
            await session.start()
            if let uid = session.userId {
                groupsViewModel.start(uid: uid)
                tripViewModel.start(uid: uid)
                historyViewModel.start(uid: uid)
                checkInViewModel.start(uid: uid)
                alertsViewModel.start(uid: uid)
                safetyMonitor.update(trip: tripViewModel.activeTrip)
                guardianViewModel.start(uid: uid, savedSelection: session.user?.selectedStudentId)
                studentHomeViewModel.startFollowingLocation()
            }
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}
