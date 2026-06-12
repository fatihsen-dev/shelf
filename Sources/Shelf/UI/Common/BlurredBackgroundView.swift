import AppKit

final class BlurredBackgroundView: NSVisualEffectView {
    init(material: NSVisualEffectView.Material = .popover) {
        super.init(frame: .zero)
        self.material = material
        self.blendingMode = .behindWindow
        self.state = .active
        self.wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }
}
