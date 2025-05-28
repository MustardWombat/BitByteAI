import SwiftUI

struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background color matching the storyboard
            Color(red: 0.937, green: 0.255, blue: 0.212)
                .ignoresSafeArea()
            
            // Logo centered with animation
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
    
    private var logoSize: CGFloat {
        #if os(macOS)
        return 200 // Slightly larger for macOS
        #else
        return 150 // Original iOS size
        #endif
    }
}
