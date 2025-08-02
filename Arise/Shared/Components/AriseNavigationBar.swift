import SwiftUI

struct AriseNavigationBar: View {
    let title: String
    var leadingButton: AnyView?
    var trailingButton: AnyView?
    
    init(
        title: String,
        leadingButton: AnyView? = nil,
        trailingButton: AnyView? = nil
    ) {
        self.title = title
        self.leadingButton = leadingButton
        self.trailingButton = trailingButton
    }
    
    var body: some View {
        HStack(spacing: AriseSpacing.medium) {
            // Leading button
            if let leadingButton = leadingButton {
                leadingButton
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title
            Text(title)
                .ariseTitleFont()
                .lineLimit(1)
            
            Spacer()
            
            // Trailing button
            if let trailingButton = trailingButton {
                trailingButton
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, AriseSpacing.medium)
        .padding(.vertical, AriseSpacing.xSmall)
    }
}

// MARK: - Convenience Initializers
extension AriseNavigationBar {
    init(
        title: String,
        leadingIcon: String? = nil,
        leadingAction: (() -> Void)? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        
        if let leadingIcon = leadingIcon, let leadingAction = leadingAction {
            self.leadingButton = AnyView(
                Button(action: leadingAction) {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.arisePrimaryFallback)
                        .frame(width: 44, height: 44)
                }
            )
        } else {
            self.leadingButton = nil
        }
        
        if let trailingIcon = trailingIcon, let trailingAction = trailingAction {
            self.trailingButton = AnyView(
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.arisePrimaryFallback)
                        .frame(width: 44, height: 44)
                }
            )
        } else {
            self.trailingButton = nil
        }
    }
}

// MARK: - View Extension
extension View {
    func ariseNavigationBar(
        title: String,
        leadingIcon: String? = nil,
        leadingAction: (() -> Void)? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 0) {
            AriseNavigationBar(
                title: title,
                leadingIcon: leadingIcon,
                leadingAction: leadingAction,
                trailingIcon: trailingIcon,
                trailingAction: trailingAction
            )
            
            self
                .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        AriseNavigationBar(
            title: "Alarms",
            leadingIcon: "arrow.left",
            leadingAction: { print("Back") },
            trailingIcon: "plus",
            trailingAction: { print("Add") }
        )
        
        Divider()
        
        Spacer()
    }
}