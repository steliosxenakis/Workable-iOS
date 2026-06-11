import SwiftUI

struct IPhoneFrameView<Content: View>: View {
    let content: Content
    
    private let screenWidth: CGFloat = 393
    private let screenHeight: CGFloat = 852
    private let bezelWidth: CGFloat = 12
    private let outerCornerRadius: CGFloat = 55
    private let innerCornerRadius: CGFloat = 47
    private let frameColor = Color(hex: "2C2C2E")
    private let frameBorderColor = Color(hex: "48484A")
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Outer device shell
            RoundedRectangle(cornerRadius: outerCornerRadius, style: .continuous)
                .fill(frameColor)
                .overlay(
                    RoundedRectangle(cornerRadius: outerCornerRadius, style: .continuous)
                        .strokeBorder(frameBorderColor, lineWidth: 1)
                )
            
            // Side button accents (right: power, left: volume + action)
            HStack {
                // Volume buttons (left side)
                VStack(spacing: 12) {
                    // Action button
                    RoundedRectangle(cornerRadius: 2)
                        .fill(frameBorderColor)
                        .frame(width: 3, height: 28)
                    
                    // Volume up
                    RoundedRectangle(cornerRadius: 2)
                        .fill(frameBorderColor)
                        .frame(width: 3, height: 44)
                    
                    // Volume down
                    RoundedRectangle(cornerRadius: 2)
                        .fill(frameBorderColor)
                        .frame(width: 3, height: 44)
                }
                .offset(x: -1, y: -100)
                
                Spacer()
                
                // Power button (right side)
                RoundedRectangle(cornerRadius: 2)
                    .fill(frameBorderColor)
                    .frame(width: 3, height: 72)
                    .offset(x: 1, y: -80)
            }
            
            // Screen area
            ZStack(alignment: .top) {
                // Screen content
                content
                    .frame(width: screenWidth, height: screenHeight)
                    .clipShape(RoundedRectangle(cornerRadius: innerCornerRadius, style: .continuous))
                
                // Dynamic Island
                DynamicIslandView()
                    .padding(.top, 11)
            }
        }
        .frame(
            width: screenWidth + bezelWidth * 2,
            height: screenHeight + bezelWidth * 2
        )
    }
}

struct DynamicIslandView: View {
    var body: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: 126, height: 37)
    }
}

#Preview("iPhone 17 Pro Frame") {
    ZStack {
        Color(hex: "E8E8ED")
            .ignoresSafeArea()
        
        IPhoneFrameView {
            NavigationStack {
                CandidatesBrowserView()
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 40, x: 0, y: 20)
        .scaleEffect(0.7)
    }
}
