import Foundation
import Combine

// application status managing view model
final class AppStateViewModel: ObservableObject {
    @Published private(set) var state: AppStatus = .auth(.signIn)
    
// show home view
    func showHome(){
        state = .main(.home)
    }
    
// show signIn form
    func showSignIn(){
        state = .auth(.signIn)
    }
    
// show signUp form
    func showSignUp(){
        state = .auth(.signUp)
    }
    
// show password reset form
    func showPasswordReset(){
        state = .auth(.passwordReset)
    }
    
// signout from the application
    func signOut() {
        state = .auth(.signIn)
    }
}
