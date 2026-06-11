import SwiftUI

/// Built-in native ad templates, all implemented in SwiftUI as of v3.
public enum NativeAdViewStyle: CaseIterable, Sendable {
    /// Free-form layout with full body text and centered media (former XIB).
    case basic
    /// Media-led card with icon, rating row and a prominent CTA.
    case card
    /// Compact text-only row with the app icon on the right; no media.
    case banner
    /// Media on the left, text column on the right.
    case largeBanner

    @MainActor @ViewBuilder
    func makeBody(assets: NativeAdAssets) -> some View {
        switch self {
        case .basic:
            NativeAdBasicTemplate(assets: assets)
        case .card:
            NativeAdCardTemplate(assets: assets)
        case .banner:
            NativeAdBannerTemplate(assets: assets)
        case .largeBanner:
            NativeAdLargeBannerTemplate(assets: assets)
        }
    }
}
