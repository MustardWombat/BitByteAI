import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - LayoutShell
struct LayoutShell: View {
    @Binding var currentView: String
    let content: AnyView

    @State private var isShellWiped = false      // new: control shell wipe

    @EnvironmentObject var timerModel: StudyTimerModel 
    private let topBarHeight: CGFloat = 100
    private let bottomBarHeight: CGFloat = 90

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Content (lowest z-index)
                VStack(spacing: 0) {
                    // Top Bar
                    AppHeader(currentView: $currentView)
                        .environmentObject(timerModel)
                    
                    // Main Content
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, bottomBarHeight) // Add padding to prevent content from being hidden behind bottom bar
                }
                .zIndex(0)
                
                // Bottom bar - highest z-index to stay on top
                BottomBar(currentView: $currentView)
                    .frame(height: bottomBarHeight)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - bottomBarHeight / 2 + (isShellWiped ? bottomBarHeight : 0)
                    )
                    .animation(.easeInOut(duration: 1), value: isShellWiped)
                    .zIndex(999) // Ensure it's always on top
            }
        }
        .background(Color.clear)
        .onAppear {
            updateXPValues()
        }
    }
    
    private func updateXPValues() {
        // Replace with actual logic to fetch or calculate XP values
        //currentXP = 150 // Example current XP value
        //maxXP = 200 // Example max XP value
    }
    
    /// Call this to wipe the shell UI off screen
    func wipeShell() {
        isShellWiped = true
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
        Color.gray.opacity(0.2) // Use a simple gray background as a fallback
    }
}
#endif

// Add notification name for wiping shell
extension Notification.Name {
    static let wipeShell = Notification.Name("wipeShell")
    static let restoreShell = Notification.Name("restoreShell")
}
