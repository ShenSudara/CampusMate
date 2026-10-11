import SwiftUI

struct LocationPermissionBanner: View {
    let isDenied: Bool
    let onAllow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(isDenied ? "Location access is off" : "Allow location access",
                  systemImage: isDenied ? "location.slash.fill" : "location.fill")
                .font(.headline)
                .foregroundColor(isDenied ? .red : .accentColor)
            Text(isDenied
                 ? "CampusMate can't share your journey without your location. Open Settings, tap Location and choose \"Always\" or \"While Using the App\"."
                 : "CampusMate shares your location only while a journey is active, so your guardians can follow you safely to your destination.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if isDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button("Allow Location", action: onAllow)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    VStack {
        LocationPermissionBanner(isDenied: false, onAllow: {})
        LocationPermissionBanner(isDenied: true, onAllow: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
