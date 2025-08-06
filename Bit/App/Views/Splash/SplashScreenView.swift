import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            MainView() // Changed from NavigatorModule to MainView
        } else {
            SplashScreenOverlay()
                .onDisappear {
                    self.isActive = true
                }
        }
    }
}

struct SplashScreenOverlay: View {
    @State private var size = 1.0
    @State private var opacity = 1.0
    @State private var overlayOpacity: Double = 1.0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background color #EF4136
            Color(red: 239/255, green: 65/255, blue: 54/255)
                .edgesIgnoringSafeArea(.all) // Use edgesIgnoringSafeArea for older iOS versions
                .ignoresSafeArea() // Use ignoresSafeArea for newer iOS versions
            
            // App Icon - already fully visible
            Image("Logo")
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .frame(width: 150, height: 150)
                .scaleEffect(size)
                .opacity(opacity)
        }
        .opacity(overlayOpacity)
        .drawingGroup()
        .edgesIgnoringSafeArea(.all) // Ensure the entire ZStack ignores safe areas
        .onAppear {
            // No fade-in animation needed
            
            // Just wait and then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.7)) {
                    overlayOpacity = 0
                }
            }
        }
    }
}
