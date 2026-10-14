import SwiftUI

struct MainTabView: View {
    enum Tab {
        case home, destination, history, groups, profile
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
                             onOpenDestination: { selectedTab = .destination })
                        .tabItem { Label("Home", systemImage: session.mode.systemImage) }
                        .tag(Tab.home)
                    if session.mode == .student {
                        DestinationMapView(viewModel: studentHomeViewModel,
                                           tripViewModel: tripViewModel,
                                           groupsViewModel: groupsViewModel,
                                           session: session)
                            .tabItem { Label("Destination", systemImage: "map") }
                            .tag(Tab.destination)
                    }
                    TripHistoryView(viewModel: historyViewModel, mode: session.mode)
                        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                        .tag(Tab.history)
                    GroupListView(viewModel: groupsViewModel, session: session)
                        .tabItem { Label("Groups", systemImage: "person.3") }
                        .tag(Tab.groups)
                    ProfileView(session: session, authViewModel: authViewModel, alertsViewModel: alertsViewModel)
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(Tab.profile)
                }
                .onChange(of: session.mode) { mode in
                    if mode == .guardian && selectedTab == .destination {
                        selectedTab = .home
                    }
                }
            }
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
            tripViewModel.stop()
            guardianViewModel.stop()
            historyViewModel.stop()
            checkInViewModel.stop()
            alertsViewModel.stop()
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
                guardianViewModel.start(uid: uid, savedSelection: session.user?.selectedStudentId)
                studentHomeViewModel.startFollowingLocation()
            }
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}
