import Foundation
import Combine

// application status managing view model
final class AppStateViewModel: ObservableObject {
    @Published private(set) var state: AppStatus = .main(.home)
        
// signout from the application
    func signOut() {
        state = .auth(.signIn)
    }
}
