import AppKit

enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let window: CGFloat = 16
    }

    enum Font {
        static let title = NSFont.systemFont(ofSize: 14, weight: .semibold)
        static let body = NSFont.systemFont(ofSize: 13, weight: .regular)
        static let mono = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        static let caption = NSFont.systemFont(ofSize: 11, weight: .regular)
        static let search = NSFont.systemFont(ofSize: 16, weight: .regular)
    }

    enum Color {
        static var accent: NSColor { NSColor.controlAccentColor }
        static var primaryText: NSColor { NSColor.labelColor }
        static var secondaryText: NSColor { NSColor.secondaryLabelColor }
        static var tertiaryText: NSColor { NSColor.tertiaryLabelColor }
        static var separator: NSColor { NSColor.separatorColor }
        static var selection: NSColor { NSColor.controlAccentColor.withAlphaComponent(0.18) }
        static var hover: NSColor { NSColor.labelColor.withAlphaComponent(0.06) }
        static var iconBackground: NSColor { NSColor.labelColor.withAlphaComponent(0.08) }
    }

    enum Sizes {
        static let cellHeight: CGFloat = 56
        static let iconSize: CGFloat = 32
        static let searchHeight: CGFloat = 48
        static let windowWidth: CGFloat = 480
        static let windowHeight: CGFloat = 540
    }
}
