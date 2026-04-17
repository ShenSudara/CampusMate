import SwiftUI

@main
struct CampusMateApp: App {
// application view models instances injected as a environment objects to the application context
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var signInViewModel = SignInViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(signInViewModel)
        }
    }
}
