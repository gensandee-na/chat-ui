import UIKit

/// Routes haptic events from the WebView bridge to the platform's
/// UIFeedbackGenerator family.
final class HapticsService {
    func fire(_ style: BridgeMessage.HapticStyle) {
        switch style {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .impact:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
