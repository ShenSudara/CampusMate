import SwiftUI

struct HomeView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var studentHomeViewModel: StudentHomeViewModel
    @ObservedObject var tripViewModel: TripViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
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
                    VStack(spacing: 16) {
                        Image(systemName: session.mode.systemImage)
                            .font(.system(size: 56))
                            .foregroundColor(.accentColor)
                        Text("Hi, \(session.user?.displayName ?? "")")
                            .font(.title2.bold())
                        Text("You are in Guardian mode.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle(session.mode.title)
        }
    }
}

#Preview {
    HomeView(session: SessionViewModel(),
             studentHomeViewModel: StudentHomeViewModel(),
             tripViewModel: TripViewModel(),
             groupsViewModel: GroupsViewModel(),
             onOpenDestination: {})
}
