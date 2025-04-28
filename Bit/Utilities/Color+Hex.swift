#if canImport(UIKit)
import SwiftUI
import UIKit

extension Color {
    public func toHex() -> String { // updated: added public access level
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rInt = Int(r * 255)
        let gInt = Int(g * 255)
        let bInt = Int(b * 255)
        return String(format: "#%02X%02X%02X", rInt, gInt, bInt)
    }
}
#elseif canImport(AppKit)
import SwiftUI
import AppKit

extension Color {
    public func toHex() -> String { // updated: added public access level
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rInt = Int(r * 255)
        let gInt = Int(g * 255)
        let bInt = Int(b * 255)
        return String(format: "#%02X%02X%02X", rInt, gInt, bInt)
    }
}
#endif
