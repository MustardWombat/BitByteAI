import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - TopShellSpritePlaceholder
struct TopShellSpritePlaceholder: View {
    @AppStorage("profileImageData") private var profileImageData: Data? // Store profile image in AppStorage
    @AppStorage("hasSubscription") private var isPro: Bool = false  // ← new
    @Binding var currentView: String // Add binding to navigate to ProfileView

    var body: some View {
        Button(action: {
            currentView = "Profile" // Navigate to ProfileView
        }) {
            if let imageData = profileImageData {
                #if os(iOS)
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .cornerRadius(8) // Rounded corners
                        // gradient glow when Pro
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isPro
                                        ? AnyShapeStyle(
                                            AngularGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                center: .center
                                            )
                                        )
                                        : AnyShapeStyle(Color.white),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: isPro ? Color.orange.opacity(0.7) : Color.clear,
                                radius: isPro ? 8 : 0)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .cornerRadius(8) // Rounded corners
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isPro
                                        ? AnyShapeStyle(
                                            AngularGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                center: .center
                                            )
                                        )
                                        : AnyShapeStyle(Color.white),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: isPro ? Color.orange.opacity(0.7) : Color.clear,
                                radius: isPro ? 8 : 0)
                }
                #endif
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .overlay(Text("Add").foregroundColor(.white))
            }
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
    }
}

// MARK: - AppHeader (Clean header component)
struct AppHeader: View {
    @Binding var currentView: String
    
    @State private var isShellWiped = false

    @EnvironmentObject var timerModel: StudyTimerModel
    
    private let topBarHeight: CGFloat = 100
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea(edges: .top)
                .frame(height: topBarHeight)
            
            VStack(spacing: 4) {
                HStack(spacing: 12) {
                    // Left-aligned items
                    HStack(spacing: 12) {
                        CoinDisplay()
                            .font(.caption.monospaced())
                            .foregroundColor(Color.green)
                        StreakDisplay()
                            .environmentObject(timerModel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right-aligned items
                    HStack(spacing: 12) {
                        XPDisplayView()
                        TopShellSpritePlaceholder(currentView: $currentView)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                
                MarqueeText(text: currentView == "Home" ? "Welcome back, Commander!" : dynamicWelcomeText(for: currentView))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .frame(height: topBarHeight)
        .offset(y: isShellWiped ? -topBarHeight * 2 : 0)
        .animation(.easeInOut(duration: 1), value: isShellWiped)
        .onReceive(NotificationCenter.default.publisher(for: .wipeShell)) { _ in
            withAnimation { isShellWiped = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .restoreShell)) { _ in
            withAnimation { isShellWiped = false }
        }
    }
    
    private func dynamicWelcomeText(for view: String) -> String {
        switch view {
        case "Tasks": return "Explore the galaxy!"
        case "Launch": return "Focus and achieve greatness!"
        case "Shop": return "Upgrade your journey!"
        default: return "Welcome back, Commander!"
        }
    }
}

// MARK: - MarqueeText
struct MarqueeText: View {
    let text: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let containerW = geo.size.width
            HStack {
                Text(text)
                    .fixedSize() // ensure full text renders without truncation
                    .background(GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textWidth = textGeo.size.width
                            containerWidth = containerW
                            offset = containerW  // start off-screen on the right
                            startScrolling()
                        }
                    })
                    .offset(x: offset)
            }
            .frame(width: containerW, alignment: .leading)
            .clipped()
        }
    }
    
    private func startScrolling() {
        guard textWidth > 0, containerWidth > 0 else { return }
        let totalDistance = textWidth + containerWidth
        let duration = Double(totalDistance) / 30.0  // adjust speed (30 points per second)
        
        // Animate from the starting offset to the position where the text's right edge is off-screen
        withAnimation(Animation.linear(duration: duration)) {
            offset = -textWidth
        }
        // After the animation completes, reset and start again
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            offset = containerWidth
            startScrolling()
        }
    }
}
