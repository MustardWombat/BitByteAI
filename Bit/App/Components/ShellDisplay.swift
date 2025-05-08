import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - BottomBarButton
struct BottomBarButton: View {
    let iconName: String
    let viewName: String
    @Binding var currentView: String

    var body: some View {
        Button(action: {
            if currentView != viewName {
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif
                currentView = viewName
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(currentView == viewName ? Color.green : Color.white)

                Text(viewName)
                    .font(.caption)
                    .foregroundColor(currentView == viewName ? Color.green : Color.white)
            }
        }
        .buttonStyle(TransparentButtonStyle()) // Apply the transparent style
    }
}

// MARK: - TopShellSpritePlaceholder
struct TopShellSpritePlaceholder: View {
    @AppStorage("profileImageData") private var profileImageData: Data? // Store profile image in AppStorage
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
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .cornerRadius(8) // Rounded corners
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
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

// MARK: - LayoutShell
struct LayoutShell: View {
    @Binding var currentView: String
    let content: AnyView
    
    @State private var currentXP: Int = 150 // Example current XP value
    @State private var maxXP: Int = 200 // Example max XP value
    @State private var funFact: String = "Loading fun fact..." // Fun fact state
    @EnvironmentObject var timerModel: StudyTimerModel // Inject StudyTimerModel
    
    
    // Define fixed heights for overlays
    private let topBarHeight: CGFloat = 100
    private let bottomBarHeight: CGFloat = 90
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top Bar
                ZStack {
                    AdaptiveBlurView(style: .regular)
                        .ignoresSafeArea(edges: .top)
                        .frame(height: topBarHeight)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(1.0), Color.black.opacity(0.05)]), // Adjusted gradient
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea(edges: .top)
                        ) // Updated fading black effect
                    VStack(spacing: 4) {
                        // --- Reordered Info row ---
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
                                TopShellSpritePlaceholder(currentView: $currentView) // Profile picture
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        // Replace static text with scrolling fun fact for Home view
                        if currentView == "Home" {
                            MarqueeText(text: funFact)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        } else {
                            Text(dynamicWelcomeText(for: currentView))
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: topBarHeight)
                .zIndex(2) // Bring the top bar above the main content.
                
                // Main Content
                content
                    .frame(maxWidth: .infinity, maxHeight: geo.size.height - topBarHeight - bottomBarHeight)
                
                // Bottom Bar
                BottomBar(currentView: $currentView)
                    .frame(height: bottomBarHeight)
                    .ignoresSafeArea(edges: .bottom)
                    .zIndex(2) // Ensure the bottom bar stays above the content.
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            updateXPValues()
        }
    }
    
    private func dynamicWelcomeText(for view: String) -> String {
        switch view {
        case "Planets": return "Explore the galaxy!"
        case "Launch": return "Focus and achieve greatness!" // Updated from "Study"
        case "Shop": return "Upgrade your journey!"
        default: return "Welcome back, Commander!"
        }
    }
    
    private func updateXPValues() {
        // Replace with actual logic to fetch or calculate XP values
        currentXP = 150 // Example current XP value
        maxXP = 200 // Example max XP value
    }
    
    
    // Updated MarqueeText view: scrolls until the text’s right edge passes the container’s left edge using a recursive animation
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
            
            // Animate from the starting offset to the position where the text’s right edge is off-screen
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
    
    // MARK: - BottomBar
    struct BottomBar: View {
        @Binding var currentView: String
        
        var body: some View {
            HStack {
                BottomBarButton(iconName: "house.fill", viewName: "Home", currentView: $currentView)
                    .frame(maxWidth: .infinity)
                BottomBarButton(iconName: "globe", viewName: "Planets", currentView: $currentView)
                    .frame(maxWidth: .infinity)
                BottomBarButton(iconName: "airplane", viewName: "Launch", currentView: $currentView) // Updated icon to "airplane"
                    .frame(maxWidth: .infinity)
                BottomBarButton(iconName: "cart.fill", viewName: "Shop", currentView: $currentView)
                    .frame(maxWidth: .infinity)
                BottomBarButton(iconName: "person.2.fill", viewName: "Friends", currentView: $currentView)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(
                Color.black.opacity(0.65)
                    .adaptiveCornerRadius(20, corners: [.topLeft, .topRight])
            )
            .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: -5)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // MARK: - BlurEffect Style (cross-platform)
#if os(iOS)
    typealias BlurEffectStyle = UIBlurEffect.Style
#else
    enum BlurEffectStyle {
        case systemMaterial
        case systemThinMaterial
        case systemUltraThinMaterial
        case systemThickMaterial
        case systemChromeMaterial
        case prominent
        case regular
    }
#endif
    
    // MARK: - BlurView
#if os(iOS)
    struct BlurView: UIViewRepresentable {
        var style: BlurEffectStyle
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            UIVisualEffectView(effect: UIBlurEffect(style: style))
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }
#else
    struct BlurView: View {
        var style: BlurEffectStyle
        
        var body: some View {
            Color.gray.opacity(0.5) // Use a simple gray background as a fallback
        }
    }
#endif
}
