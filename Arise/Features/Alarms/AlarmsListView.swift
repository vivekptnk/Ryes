import SwiftUI

struct AlarmsListView: View {
    @State private var alarms: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                if alarms.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "alarm")
                            .font(.system(size: 60))
                            .foregroundColor(.arisePrimaryFallback)
                        Text("No Alarms")
                            .ariseLargeTitleFont()
                        Text("Tap the + button to create your first alarm")
                            .ariseBodyFont()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List(alarms, id: \.self) { alarm in
                        Text(alarm)
                    }
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Navigate to alarm creation
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    AlarmsListView()
}