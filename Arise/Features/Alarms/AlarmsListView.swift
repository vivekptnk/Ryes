import SwiftUI

struct AlarmsListView: View {
    @State private var alarms: [String] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if alarms.isEmpty {
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: AriseSpacing.large) {
                            Image(systemName: "alarm")
                                .font(.system(size: 60))
                                .foregroundColor(.arisePrimaryFallback)
                            
                            VStack(spacing: AriseSpacing.small) {
                                Text("No Alarms")
                                    .ariseTitleFont()
                                    .fontWeight(.semibold)
                                
                                Text("Tap the + button to create your first alarm")
                                    .ariseBodyFont()
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                    }
                } else {
                    List(alarms, id: \.self) { alarm in
                        Text(alarm)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Navigate to alarm creation
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
            }
        }
    }
}

#Preview {
    AlarmsListView()
}