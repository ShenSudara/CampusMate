import SwiftUI

struct HomeView: View {
    @ObservedObject var session: SessionViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: session.mode.systemImage)
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                Text("Hi, \(session.user?.displayName ?? "")")
                    .font(.title2.bold())
                Text("You are in \(session.mode.title) mode.")
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle(session.mode.title)
        }
    }
}

#if DEBUG
#Preview("Student") {
    HomeView(session: .preview(user: PreviewData.student))
}

#Preview("Guardian") {
    HomeView(session: .preview(user: PreviewData.guardian))
}
#endif
