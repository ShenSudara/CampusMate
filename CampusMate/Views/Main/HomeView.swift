import SwiftUI

struct HomeView: View {
    @ObservedObject var session: SessionViewModel
    @ObservedObject var studentHomeViewModel: StudentHomeViewModel
    @ObservedObject var tripViewModel: TripViewModel
    @ObservedObject var groupsViewModel: GroupsViewModel
    @ObservedObject var guardianViewModel: GuardianViewModel
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
                    GuardianHomeView(viewModel: guardianViewModel)
                        .navigationBarTitleDisplayMode(.inline)
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
             guardianViewModel: GuardianViewModel(),
             onOpenDestination: {})
}
