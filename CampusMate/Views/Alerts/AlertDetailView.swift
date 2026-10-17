import SwiftUI
import MapKit

struct AlertDetailView: View {
    let alert: SafetyAlert

    var body: some View {
        List {
            Section {
                AlertRowView(alert: alert)
            }

            if let coordinate = alert.coordinate {
                Section("Last known location") {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))),
                        annotationItems: [alert]) { _ in
                        MapMarker(coordinate: coordinate, tint: .red)
                    }
                    .frame(height: 240)
                    .listRowInsets(EdgeInsets())
                    .accessibilityElement()
                    .accessibilityLabel("Map showing where \(alert.studentName) was when this alert was raised")

                    Button {
                        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                        item.name = "\(alert.studentName) (\(alert.type.title))"
                        item.openInMaps()
                    } label: {
                        Label("Open in Maps", systemImage: "map")
                    }
                    .accessibilityHint("Shows this location in the Maps app for directions")
                }
            } else {
                Section {
                    Text("No location was available when this alert was raised.")
                        .foregroundColor(.secondary)
                }
            }

            Section("Details") {
                LabeledContent("Student", value: alert.studentName)
                LabeledContent("Raised", value: alert.createdAt.formatted(date: .abbreviated, time: .standard))
            }
        }
        .navigationTitle(alert.type.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AlertDetailView(alert: SafetyAlert(type: .missedCheckIn, studentId: "alex", studentName: "Alex Perera",
                                           tripId: "t1", memberIds: ["alex", "maya"],
                                           message: "Alex Perera didn't respond to Maya Perera's check-in.",
                                           createdAt: Date(), createdBy: "maya",
                                           latitude: 6.9063, longitude: 79.8706))
    }
}
