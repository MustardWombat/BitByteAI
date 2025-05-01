import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - BlurView
public struct AdaptiveBlurView: View {
    private let style: BlurStyle
    
    public init(style: BlurStyle) {
        self.style = style
    }
    
    public var body: some View {
        #if os(iOS)
        // iOS implementation
        UIBlurViewRepresentable(style: style.uiBlurStyle)
        #elseif os(macOS)
        // macOS implementation
        VisualEffectView(material: style.nsMaterial, blendingMode: .behindWindow)
        #else
        // Fallback for other platforms
        Color.black.opacity(0.2)
        #endif
    }
}

// MARK: - Unified Blur Style
public enum BlurStyle {
    case thin
    case regular
    case thick
    case ultraThin
    case prominent
    
    #if os(iOS)
    var uiBlurStyle: UIBlurEffect.Style {
        switch self {
        case .thin: return .light
        case .regular: return .regular
        case .thick: return .dark
        case .ultraThin: return .systemUltraThinMaterial
        case .prominent: return .prominent
        }
    }
    #endif
    
    #if os(macOS)
    var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case .thin: return .light
        case .regular: return .contentBackground
        case .thick: return .dark
        case .ultraThin: return .menu
        case .prominent: return .titlebar
        }
    }
    #endif
}

// Platform-specific implementations
#if os(iOS)
struct UIBlurViewRepresentable: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#elseif os(macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif

// MARK: - Rounded Corners Extension
public extension View {
    func adaptiveCornerRadius(_ radius: CGFloat, corners: UIRectCornerType = .allCorners) -> some View {
        #if os(iOS)
        return clipShape(AdaptiveRoundedRectangle(radius: radius, corners: corners))
        #else
        return clipShape(RoundedRectangle(cornerRadius: radius))
        #endif
    }
}

// Define a cross-platform corners type
public struct UIRectCornerType: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let topLeft = UIRectCornerType(rawValue: 1 << 0)
    public static let topRight = UIRectCornerType(rawValue: 1 << 1)
    public static let bottomLeft = UIRectCornerType(rawValue: 1 << 2)
    public static let bottomRight = UIRectCornerType(rawValue: 1 << 3)
    public static let allCorners: UIRectCornerType = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    
    #if os(iOS)
    var uiRectCorner: UIRectCorner {
        var result: UIRectCorner = []
        if self.contains(.topLeft) { result.insert(.topLeft) }
        if self.contains(.topRight) { result.insert(.topRight) }
        if self.contains(.bottomLeft) { result.insert(.bottomLeft) }
        if self.contains(.bottomRight) { result.insert(.bottomRight) }
        return result
    }
    #endif
}

#if os(iOS)
struct AdaptiveRoundedRectangle: Shape {
    let radius: CGFloat
    let corners: UIRectCornerType
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners.uiRectCorner,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#endif
