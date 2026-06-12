import AppKit

enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 6
        static let m: CGFloat = 8
        static let l: CGFloat = 12
        static let xl: CGFloat = 16
    }

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 14
        static let shelf: CGFloat = 24
    }

    enum Font {
        static let body      = NSFont.systemFont(ofSize: 12.5, weight: .regular)
        static let bodyBold  = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
        static let caption   = NSFont.systemFont(ofSize: 11,   weight: .regular)
        static let captionBold = NSFont.systemFont(ofSize: 11, weight: .medium)
        static let mono      = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
        static let search    = NSFont.systemFont(ofSize: 13,   weight: .regular)
        static let chip      = NSFont.systemFont(ofSize: 12,   weight: .medium)
        static let badge     = NSFont.systemFont(ofSize: 9.5,  weight: .regular)
        static let badgeBold = NSFont.systemFont(ofSize: 9.5,  weight: .bold)
        static let hint      = NSFont.systemFont(ofSize: 11,   weight: .regular)
    }

    enum Color {
        static let accent      = NSColor(hex: "e5484d")
        static let accentSoft  = NSColor(hex: "e5484d").withAlphaComponent(0.14)
        static let accentRing  = NSColor(hex: "e5484d").withAlphaComponent(0.55)

        static var text: NSColor        { .labelColor }
        static var textDim: NSColor     { .secondaryLabelColor }
        static var textFaint: NSColor   { .tertiaryLabelColor }
        static var divider: NSColor     { .separatorColor }

        static var field: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? .white.withAlphaComponent(0.08)
                : .black.withAlphaComponent(0.05)
            }
        }
        static var fieldFocus: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? .white.withAlphaComponent(0.13)
                : .white.withAlphaComponent(0.95)
            }
        }
        static var card: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? NSColor(white: 0.225, alpha: 0.82)
                : NSColor(white: 1,     alpha: 0.94)
            }
        }
        static var cardBorder: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? .white.withAlphaComponent(0.09)
                : .black.withAlphaComponent(0.08)
            }
        }
        static var chip: NSColor        { field }
        static var chipText: NSColor    { textDim }
        static var selection: NSColor   { NSColor.controlAccentColor.withAlphaComponent(0.18) }
        static var hover: NSColor       { NSColor.labelColor.withAlphaComponent(0.06) }

        // Settings window surfaces
        static var winBackground: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? NSColor(red: 0.157, green: 0.141, blue: 0.173, alpha: 1)
                : NSColor(red: 0.965, green: 0.961, blue: 0.973, alpha: 1)
            }
        }
        static var winSidebar: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? NSColor(red: 0.110, green: 0.098, blue: 0.125, alpha: 1)
                : NSColor(red: 0.910, green: 0.906, blue: 0.933, alpha: 1)
            }
        }
        static var winCard: NSColor {
            NSColor(name: nil) { $0.name == .darkAqua
                ? NSColor(red: 0.227, green: 0.212, blue: 0.243, alpha: 1)
                : NSColor(red: 1,     green: 1,     blue: 1,     alpha: 0.92)
            }
        }
    }

    enum Sizes {
        static let cardWidth:   CGFloat = 214
        static let cardHeight:  CGFloat = 158
        static let cardGap:     CGFloat = 11
        static let railPadV:    CGFloat = 6
        static let searchH:     CGFloat = 34
        static let topBarH:     CGFloat = 61   // searchH + top padding + bottom margin
        static let footerH:     CGFloat = 32
        static let shelfPadH:   CGFloat = 16
        static let shelfPadTop: CGFloat = 14
        static let shelfPadBot: CGFloat = 10

        static var shelfH: CGFloat {
            shelfPadTop + searchH + 6 + railPadV * 2 + cardHeight + footerH + shelfPadBot
        }
        static var windowW: CGFloat {
            guard let screen = NSScreen.main else { return 1000 }
            return min(1360, screen.visibleFrame.width * 0.95)
        }
        static let windowBottomGap: CGFloat = 22
    }
}

extension NSView {
    func applyLayerColor(_ color: NSColor, to layer: CALayer?) {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = color.cgColor
        }
    }
}

extension NSColor {
    convenience init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var n: UInt64 = 0
        Scanner(string: s).scanHexInt64(&n)
        self.init(
            red:   CGFloat((n >> 16) & 0xFF) / 255,
            green: CGFloat((n >>  8) & 0xFF) / 255,
            blue:  CGFloat( n        & 0xFF) / 255,
            alpha: 1
        )
    }
}
