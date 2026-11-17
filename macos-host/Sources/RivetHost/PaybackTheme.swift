import SwiftUI

// Payback design language (design/DESIGN.md, 2026-11 redesign): warm paper
// background, ink typography, one terracotta accent pair for value and
// progress, a single green pair reserved for "goal met". Tokens are the
// prototype's shared.css values, light and dark paired explicitly — the
// host never derives one from the other.

enum PaybackTheme {
    // MARK: palette — design/prototype/shared.css, light + dark pairs

    private static func paired(_ lightHex: UInt32, _ darkHex: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let dark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return nsColor(dark ? darkHex : lightHex)
        })
    }

    private static func nsColor(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }

    /// app background
    static let paper = paired(0xFAF7F2, 0x211F1C)
    /// cards, inputs, raised surfaces
    static let surface = paired(0xFFFFFF, 0x2B2926)
    /// sidebar background
    static let sidebar = paired(0xF2EDE6, 0x25221F)
    /// primary text
    static let ink = paired(0x302D29, 0xEEE9E2)
    /// secondary text
    static let muted = paired(0x68635C, 0xB9B1A7)
    /// hairlines and separators
    static let line = paired(0xE1DCD4, 0x47413B)
    /// in-progress states and primary actions
    static let accent = paired(0xA64A2B, 0xE5A17E)
    static let accentHover = paired(0x913E23, 0xEFB596)
    /// soft accent washes (selected rows, chips, fills)
    static let soft = paired(0xF3E5DC, 0x423127)
    /// reserved exclusively for goal-met / beyond-cost states
    static let earn = paired(0x276D3B, 0x8BC79B)
    static let earnSoft = paired(0xE7F0E7, 0x293B2D)
    /// destructive actions only
    static let danger = paired(0xB32C28, 0xFF9B92)
    static let dangerSoft = paired(0xFBE9E7, 0x452D29)

    // compatibility aliases for pre-redesign call sites that mean the
    // generic surface concepts
    static let card = surface
    static let accentSoft = soft
    static let hairline = line

    // MARK: metrics

    static let radius: CGFloat = 16
    static let cardCorner: CGFloat = 16
    static let statCorner: CGFloat = 12
    static let cardPadding: CGFloat = 16

    // MARK: styles

    /// the prototype's flat card: surface fill + 1px line border, no shadow
    static func cardBackground(_ dark: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
            .fill(surface)
            .overlay(
                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                    .strokeBorder(line, lineWidth: 1)
            )
    }

    /// brand mark: accent square with the paper-colored arrow, like the
    /// prototype sidebar's .brandmark
    static var brandmark: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(accent)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(paper)
            )
    }
}

/// Linear category icon per the prototype's icon language: one symbol per
/// device category in the line style, never a device photograph. Engine
/// values map 1:1; the redesign display names (keyboard/coffee) live in
/// strings, not in the stored vocabulary.
enum CategoryIcon {
    static func symbol(for category: String) -> String {
        switch category {
        case "computer": return "desktopcomputer"
        case "accessory": return "keyboard"
        case "keyboard": return "keyboard"      // display vocabulary safety
        case "tablet": return "tablet.landscape"
        case "audio": return "hifispeaker"
        case "phone": return "iphone"
        case "appliance": return "cup.and.saucer"
        case "coffee": return "cup.and.saucer"  // display vocabulary safety
        case "watch": return "applewatch"
        case "camera": return "camera"
        case "gaming": return "gamecontroller"
        default: return "shippingbox"
        }
    }
}

/// Localized category labels. New devices pick from the prototype's seven
/// options; legacy stored values (watch/camera/gaming) keep their own
/// labels so an edit never silently rewrites them (declared in DESIGN.md).
enum CategoryLabel {    /// the prototype's form options, in prototype order, mapped onto the
    /// engine's stored values
    static var formOptions: [(value: String, key: L10n.Key)] {
        [
            ("computer", .categoryComputer),
            ("accessory", .categoryAccessory),   // 配件 — prototype "keyboard"
            ("tablet", .categoryTablet),
            ("audio", .categoryAudio),
            ("phone", .categoryPhone),
            ("appliance", .categoryAppliance),   // 家电 — prototype "coffee"
            ("other", .categoryOther)
        ]
    }

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

    /// full picker options for a device being edited: the seven canonical
    /// choices plus the record's own legacy value when it is outside them
    static func editOptions(for currentValue: String) -> [(value: String, key: L10n.Key)] {
        var options = formOptions
        if !options.contains(where: { $0.value == currentValue }) {
            let legacy: [String: L10n.Key] = [
                "watch": .categoryWatch,
                "camera": .categoryCamera,
                "gaming": .categoryGaming
            ]
            if let key = legacy[currentValue] {
                options.append((currentValue, key))
            } else {
                options.append((currentValue, .categoryOther))
            }
        }
        return options
    }
}

/// Milestone display vocabulary: engine keys are stable wire identifiers,
/// hosts localize (docs/data-format.md). The emoji set survives only in
/// the celebration overlay until the S2c restyle.
enum MilestoneBadge {
    static func emoji(for key: String) -> String {
        switch key {
        case "days-100": return "🌱"
        case "days-365": return "📅"
        case "days-1000": return "🏆"
        case "cpd-10": return "💸"
        case "cpd-5": return "🌤"
        case "cpd-2": return "🍃"
        case "cpd-1": return "🪶"
        case "cpd-05": return "✨"
        case "paid-back": return "🎉"
        default: return "🏅"
        }
    }

    /// linear symbol per the redesign icon language
    static func symbol(for key: String) -> String {
        switch key {
        case "days-100": return "leaf"
        case "days-365": return "calendar"
        case "days-1000": return "trophy"
        case "cpd-10": return "banknote"
        case "cpd-5": return "banknote"
        case "cpd-2": return "leaf"
        case "cpd-1": return "feather"
        case "cpd-05": return "sparkles"
        case "paid-back": return "checkmark.seal"
        default: return "rosette"
        }
    }

    static func label(for key: String) -> String {
        switch key {
        case "days-100": return L10n.t(.milestoneDays100)
        case "days-365": return L10n.t(.milestoneDays365)
        case "days-1000": return L10n.t(.milestoneDays1000)
        case "cpd-10": return L10n.t(.milestoneCpd10)
        case "cpd-5": return L10n.t(.milestoneCpd5)
        case "cpd-2": return L10n.t(.milestoneCpd2)
        case "cpd-1": return L10n.t(.milestoneCpd1)
        case "cpd-05": return L10n.t(.milestoneCpd05)
        case "paid-back": return L10n.t(.milestonePaidBack)
        default: return key
        }
    }
}
