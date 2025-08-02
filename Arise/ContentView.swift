import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "alarm")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Arise - AI Alarm")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}