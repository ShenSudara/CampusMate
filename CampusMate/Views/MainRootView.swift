import SwiftUI

// main application flow
struct MainRootView: View {
    let flow: MainFlow
    
    var body: some View {
        NavigationStack {
            switch flow {
            case .home:
                HomeView()
            }
        }
    }
}
