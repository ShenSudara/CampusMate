import SwiftUI

// main flow of application
struct ContentView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    
    var body: some View {
        NavigationStack {
            switch appState.state {
            case .auth(let authFlow):
                AuthRootView(flow: authFlow)
            case .main(let mainFlow):
                MainRootView(flow: mainFlow)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStateViewModel())
}
