import SwiftUI

extension Color {
    // A deeper green than the system one, so white button text stays readable in light and dark mode.
    static let confirmGreen = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.56, blue: 0.29, alpha: 1)
            : UIColor(red: 0.11, green: 0.51, blue: 0.25, alpha: 1)
    })
}
