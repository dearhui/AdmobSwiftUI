import GoogleMobileAds
import SwiftUI

/// Displays a loaded native ad using one of the built-in SwiftUI templates.
///
/// Renders nothing until ``NativeAdViewModel/nativeAd`` is available (v2
/// rendered an empty template skeleton instead). For a fully custom layout,
/// use ``AdmobNativeAdContainer`` directly.
public struct NativeAdView: View {
    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle

    public init(nativeViewModel: NativeAdViewModel, style: NativeAdViewStyle = .basic) {
        self.nativeViewModel = nativeViewModel
        self.style = style
    }

    public var body: some View {
        if let ad = nativeViewModel.nativeAd {
            AdmobNativeAdContainer(ad: ad) { assets in
                style.makeBody(assets: assets)
            }
        }
    }
}
