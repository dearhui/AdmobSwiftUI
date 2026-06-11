import GoogleMobileAds
import SwiftUI

/// The native ad asset a view represents. Views tagged with an asset kind are
/// registered on the underlying `GADNativeAdView` so the SDK attributes
/// clicks on them.
public enum NativeAdAssetKind: CaseIterable, Sendable {
    /// The ad headline. Google requires it to be displayed.
    case headline
    /// The call-to-action text (e.g. "Install").
    case callToAction
    /// The advertiser's icon image.
    case icon
    /// The ad body text.
    case body
    /// The app store name (app-install ads).
    case store
    /// The price string (app-install ads).
    case price
    /// A large ad image.
    case image
    /// The app's star rating (app-install ads).
    case starRating
    /// The advertiser name.
    case advertiser
}

public extension View {
    /// Tags this view as displaying the given native ad asset.
    ///
    /// Only has an effect inside ``AdmobNativeAdContainer``. Apply it after
    /// padding/background modifiers so the whole visual region is tappable.
    /// Prefer the pre-bound components on ``NativeAdAssets``; reach for this
    /// modifier when rendering an asset with your own views.
    func nativeAdAsset(_ kind: NativeAdAssetKind) -> some View {
        overlay(NativeAdAssetProxy(kind: kind))
    }
}

/// A transparent UIKit view layered over a SwiftUI-rendered asset. It is the
/// view registered on the `GADNativeAdView` outlet, so SDK tap handling lands
/// on it while SwiftUI does the drawing.
struct NativeAdAssetProxy: UIViewRepresentable {
    let kind: NativeAdAssetKind
    @Environment(\.nativeAdAssetRegistry) private var registry

    final class ProxyView: UIView {
        var onDismantle: (() -> Void)?
    }

    func makeUIView(context: Context) -> ProxyView {
        let view = ProxyView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }

    func updateUIView(_ view: ProxyView, context: Context) {
        guard let registry else {
            AdmobSwiftUI.log("nativeAdAsset(.\(kind)) used outside AdmobNativeAdContainer; clicks on this view won't be attributed.", level: .warning)
            return
        }
        registry.register(view, for: kind)
        view.onDismantle = { [weak registry, weak view] in
            guard let view else { return }
            registry?.unregister(view, for: kind)
        }
    }

    static func dismantleUIView(_ view: ProxyView, coordinator: ()) {
        view.onDismantle?()
    }
}

/// Lightweight proxy over a loaded `NativeAd`. Each vended component is
/// pre-bound to its asset view, guaranteeing correct click/impression
/// attribution no matter how the layout arranges them.
///
/// Optional components are `nil` when the ad lacks that asset, so layouts
/// collapse naturally with `if let` / optional chaining.
@MainActor
public struct NativeAdAssets {
    /// The underlying native ad, for direct access to raw asset data.
    public let ad: GoogleMobileAds.NativeAd

    init(ad: GoogleMobileAds.NativeAd) {
        self.ad = ad
    }

    /// Headline text, pre-bound. Google requires the headline to be displayed.
    public var headline: NativeAdAssetText {
        NativeAdAssetText(text: ad.headline ?? "", kind: .headline)
    }

    /// Body text, pre-bound.
    public var body: NativeAdAssetText? {
        ad.body.map { NativeAdAssetText(text: $0, kind: .body) }
    }

    /// Advertiser name, pre-bound.
    public var advertiser: NativeAdAssetText? {
        ad.advertiser.map { NativeAdAssetText(text: $0, kind: .advertiser) }
    }

    /// App store name, pre-bound.
    public var store: NativeAdAssetText? {
        ad.store.map { NativeAdAssetText(text: $0, kind: .store) }
    }

    /// Price string, pre-bound.
    public var price: NativeAdAssetText? {
        ad.price.map { NativeAdAssetText(text: $0, kind: .price) }
    }

    /// Call-to-action text, pre-bound. Style it like a button (background,
    /// padding) — the tap itself is handled by the SDK, which is why this is
    /// not a `Button`.
    public var callToAction: NativeAdAssetText? {
        ad.callToAction.map { NativeAdAssetText(text: $0, kind: .callToAction) }
    }

    /// Icon image, pre-bound. Already resizable; size it with `frame` and
    /// `aspectRatio(contentMode:)`.
    public var icon: NativeAdAssetImage? {
        ad.icon?.image.map { NativeAdAssetImage(image: $0, kind: .icon) }
    }

    /// Media view (image or video), pre-bound. Size it with
    /// `aspectRatio(mediaAspectRatio, contentMode: .fit)` or an explicit frame.
    public var media: NativeAdMediaView {
        NativeAdMediaView(mediaContent: ad.mediaContent)
    }

    /// Aspect ratio of the media content; falls back to 16:9 when unknown.
    public var mediaAspectRatio: CGFloat {
        ad.mediaContent.aspectRatio > 0 ? ad.mediaContent.aspectRatio : 16.0 / 9.0
    }

    /// Star rating rendered with the bundled star images, pre-bound.
    /// `nil` when the ad has no rating or it is below 3.5 stars.
    public var starRating: NativeAdStarRatingView? {
        NativeAdStarRatingView(rating: ad.starRating)
    }
}

/// A text asset pre-bound to its `GADNativeAdView` outlet. Renders as a plain
/// `Text`, so font/color modifiers apply as usual.
public struct NativeAdAssetText: View {
    let text: String
    let kind: NativeAdAssetKind

    public var body: some View {
        Text(verbatim: text)
            .nativeAdAsset(kind)
    }
}

/// An image asset pre-bound to its `GADNativeAdView` outlet. The image is
/// resizable; size it with `frame` and `aspectRatio(contentMode:)`.
public struct NativeAdAssetImage: View {
    let image: UIImage
    let kind: NativeAdAssetKind

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .nativeAdAsset(kind)
    }
}

/// SwiftUI wrapper for `GADMediaView`, registered as the media outlet.
/// Required by AdMob policy whenever the ad contains media; video ads render
/// and play inside it.
public struct NativeAdMediaView: UIViewRepresentable {
    let mediaContent: GoogleMobileAds.MediaContent
    @Environment(\.nativeAdAssetRegistry) private var registry

    public func makeUIView(context: Context) -> GoogleMobileAds.MediaView {
        let view = GoogleMobileAds.MediaView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    public func updateUIView(_ view: GoogleMobileAds.MediaView, context: Context) {
        view.mediaContent = mediaContent
        registry?.register(mediaView: view)
    }
}

/// Star rating displayed with the bundled star images (5, 4.5, 4 and 3.5
/// stars), matching the v2 templates. Pre-bound to the starRating outlet.
public struct NativeAdStarRatingView: View {
    let image: UIImage

    init?(rating: NSDecimalNumber?) {
        guard let image = Self.image(for: rating) else { return nil }
        self.image = image
    }

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .nativeAdAsset(.starRating)
    }

    static func image(for rating: NSDecimalNumber?) -> UIImage? {
        guard let rating = rating?.doubleValue else { return nil }
        let name: String
        switch rating {
        case 5...: name = "stars_5"
        case 4.5...: name = "stars_4_5"
        case 4...: name = "stars_4"
        case 3.5...: name = "stars_3_5"
        default: return nil
        }
        return UIImage(named: name, in: .module, compatibleWith: nil)
    }
}

/// The "Ad" attribution badge used by the built-in templates. Localized via
/// the package's string catalog.
public struct AdBadge: View {
    let foregroundColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat

    /// Creates a badge with the given colors and corner radius.
    public init(foregroundColor: Color = .white,
                backgroundColor: Color = .orange,
                cornerRadius: CGFloat = 2) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Text("AD", bundle: .module)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}
