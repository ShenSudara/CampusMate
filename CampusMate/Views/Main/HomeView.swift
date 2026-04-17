import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("CampusMate")
                .font(.largeTitle)
                .bold()
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
