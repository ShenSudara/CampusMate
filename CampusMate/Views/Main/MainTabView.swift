import SwiftUI

struct MainTabView: View {
    enum Tab {
        case home, destination, groups, profile
    }

    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var session = SessionViewModel()
    @StateObject private var groupsViewModel = GroupsViewModel()
    @StateObject private var studentHomeViewModel = StudentHomeViewModel()
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
                             onOpenDestination: { selectedTab = .destination })
                        .tabItem { Label("Home", systemImage: session.mode.systemImage) }
                        .tag(Tab.home)
                    if session.mode == .student {
                        DestinationMapView(viewModel: studentHomeViewModel)
                            .tabItem { Label("Destination", systemImage: "map") }
                            .tag(Tab.destination)
                    }
                    GroupListView(viewModel: groupsViewModel, session: session)
                        .tabItem { Label("Groups", systemImage: "person.3") }
                        .tag(Tab.groups)
                    ProfileView(session: session, authViewModel: authViewModel)
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
        .task {
            await session.start()
            if let uid = session.userId {
                groupsViewModel.start(uid: uid)
            }
        }
    }
}

#Preview {
    MainTabView(authViewModel: AuthViewModel())
}
