import SwiftUI

#if os(iOS)
import UIKit
#endif

// Cross-platform blur effect style
#if os(iOS)
public typealias PlatformBlurEffectStyle = UIBlurEffect.Style
#else
public enum PlatformBlurEffectStyle {
    case systemMaterial
    case systemThinMaterial
    case systemUltraThinMaterial
    case systemThickMaterial
    case systemChromeMaterial
    case prominent
    case regular
}
#endif

// Cross-platform rect corner
public enum RectCorner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight, allCorners
    
    #if os(iOS)
    var uiRectCorner: UIRectCorner {
        switch self {
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        case .allCorners: return .allCorners
        }
    }
    #endif
}

// Cross-platform blur view
#if os(iOS)
struct PlatformBlurView: UIViewRepresentable {
    let style: PlatformBlurEffectStyle
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#else
struct PlatformBlurView: View {
    let style: PlatformBlurEffectStyle
    
    var body: some View {
        Color.gray.opacity(0.5)
    }
}
#endif

// Cross-platform rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: [RectCorner]) -> some View {
        #if os(iOS)
        let uiCorners = UIRectCorner(corners.map { $0.uiRectCorner })
        return clipShape(RoundedCornerShape(radius: radius, corners: uiCorners))
        #else
        return clipShape(RoundedRectangle(cornerRadius: radius))
        #endif
    }
}

#if os(iOS)
struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#endif
