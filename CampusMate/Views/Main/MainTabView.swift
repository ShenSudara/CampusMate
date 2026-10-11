import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var session: SessionViewModel
    @StateObject private var groupsViewModel: GroupsViewModel

    init(authViewModel: AuthViewModel,
         session: SessionViewModel? = nil,
         groupsViewModel: GroupsViewModel? = nil) {
        self.authViewModel = authViewModel
        _session = StateObject(wrappedValue: session ?? SessionViewModel())
        _groupsViewModel = StateObject(wrappedValue: groupsViewModel ?? GroupsViewModel())
    }

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
                TabView {
                    HomeView(session: session)
                        .tabItem { Label("Home", systemImage: session.mode.systemImage) }
                    GroupListView(viewModel: groupsViewModel, session: session)
                        .tabItem { Label("Groups", systemImage: "person.3") }
                    ProfileView(session: session, authViewModel: authViewModel)
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
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

#if DEBUG
#Preview {
    MainTabView(authViewModel: .preview(isSignedIn: true),
                session: .preview(),
                groupsViewModel: .preview())
}
#endif
