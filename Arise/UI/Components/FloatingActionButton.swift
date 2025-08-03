import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    let icon: String
    
    init(icon: String = "plus", action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.arisePrimary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .accessibilityLabel("Add new alarm")
        .accessibilityHint("Double tap to create a new alarm")
    }
}

struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        print("FAB tapped")
                    }
                    .padding()
                }
            }
        }
    }
}