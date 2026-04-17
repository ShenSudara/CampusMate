import Foundation

// application flow statuses
enum AppStatus {
    case auth(AuthFlow)
    case main(MainFlow)
}


// authentication flow application statuses
enum AuthFlow {
    case signIn
    case signUp
    case setupProfile
    case passwordReset
}

// main application flow statuses
enum MainFlow {
    case home
}
