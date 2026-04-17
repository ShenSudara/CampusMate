import SwiftUI

@main
struct CampusMateApp: App {
//     main application status manager injected as environment object
    @StateObject private var appState = AppStateViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
