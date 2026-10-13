import SwiftUI

// One-line status showing when the location was last sent to the group.
struct SharingStatusView: View {
    let lastSharedAt: Date?
    let errorMessage: String?

    var body: some View {
        Group {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            } else if let lastSharedAt {
                Label {
                    Text("Location shared ") + Text(lastSharedAt, style: .relative) + Text(" ago")
                } icon: {
                    Image(systemName: "location.fill")
                }
                .foregroundColor(.secondary)
            } else {
                Label("Waiting for GPS signal…", systemImage: "location.magnifyingglass")
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        SharingStatusView(lastSharedAt: Date().addingTimeInterval(-12), errorMessage: nil)
        SharingStatusView(lastSharedAt: nil, errorMessage: nil)
        SharingStatusView(lastSharedAt: nil, errorMessage: "No internet connection.")
    }
    .padding()
}
