import SwiftUI
import UIKit

// Payback design tokens for the companion (design/prototype/shared.css,
// 2026-11 redesign) — the same light/dark pairs the macOS leg uses.

enum PaybackTheme {
    private static func paired(_ lightHex: UInt32, _ darkHex: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            let dark = trait.userInterfaceStyle == .dark
            return Self.uiColor(dark ? darkHex : lightHex)
        })
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }

    static let paper = paired(0xFAF7F2, 0x211F1C)
    static let surface = paired(0xFFFFFF, 0x2B2926)
    static let sidebar = paired(0xF2EDE6, 0x25221F)
    static let ink = paired(0x302D29, 0xEEE9E2)
    static let muted = paired(0x68635C, 0xB9B1A7)
    static let line = paired(0xE1DCD4, 0x47413B)
    static let accent = paired(0xA64A2B, 0xE5A17E)
    static let soft = paired(0xF3E5DC, 0x423127)
    static let earn = paired(0x276D3B, 0x8BC79B)
    static let earnSoft = paired(0xE7F0E7, 0x293B2D)
    static let danger = paired(0xB32C28, 0xFF9B92)
}

/// Linear category icon per the prototype icon language, shared with the
/// macOS leg's mapping (docs/data-format.md stored values).
enum CategoryIcon {
    static func symbol(for category: String) -> String {
        switch category {
        case "computer": return "desktopcomputer"
        case "accessory", "keyboard": return "keyboard"
        case "tablet": return "tablet.landscape"
        case "audio": return "hifispeaker"
        case "phone": return "iphone"
        case "appliance", "coffee": return "cup.and.saucer"
        case "watch": return "applewatch"
        case "camera": return "camera"
        case "gaming": return "gamecontroller"
        default: return "shippingbox"
        }
    }
}

/// Localized category labels; the seven prototype display options map onto
/// the engine's stored values, legacy values keep their own labels
/// (declared in design/DESIGN.md).
enum CategoryLabel {
    static func label(for storedValue: String) -> String {
        switch storedValue {
        case "computer": return L10n.t(.categoryComputer)
        case "phone": return L10n.t(.categoryPhone)
        case "tablet": return L10n.t(.categoryTablet)
        case "watch": return L10n.t(.categoryWatch)
        case "audio": return L10n.t(.categoryAudio)
        case "camera": return L10n.t(.categoryCamera)
        case "gaming": return L10n.t(.categoryGaming)
        case "appliance": return L10n.t(.categoryAppliance)
        case "accessory": return L10n.t(.categoryAccessory)
        case "other": return L10n.t(.categoryOther)
        default: return L10n.t(.categoryOther)
        }
    }
}
