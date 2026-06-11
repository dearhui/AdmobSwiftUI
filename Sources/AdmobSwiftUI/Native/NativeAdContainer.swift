import GoogleMobileAds
import SwiftUI

/// Hosts a custom SwiftUI layout inside a `GADNativeAdView` so the Google
/// Mobile Ads SDK attributes impressions and clicks correctly.
///
/// Build the layout from the components vended by ``NativeAdAssets`` (or tag
/// your own views with ``SwiftUICore/View/nativeAdAsset(_:)``); each component is
/// pre-bound to its corresponding asset view, so user taps on it are billed.
///
/// ```swift
/// AdmobNativeAdContainer(ad: nativeAd) { assets in
///     VStack(alignment: .leading) {
///         HStack {
///             assets.icon?.frame(width: 40, height: 40)
///             assets.headline
///             AdBadge()
///         }
///         assets.media.aspectRatio(assets.mediaAspectRatio, contentMode: .fit)
///         assets.callToAction
///     }
/// }
/// ```
public struct AdmobNativeAdContainer<Content: View>: View {
    private let ad: GoogleMobileAds.NativeAd
    private let content: (NativeAdAssets) -> Content

    /// Creates the container.
    /// - Parameters:
    ///   - ad: The loaded native ad to render.
    ///   - content: Builds the SwiftUI layout from the ad's ``NativeAdAssets``.
    public init(ad: GoogleMobileAds.NativeAd,
                @ViewBuilder content: @escaping (NativeAdAssets) -> Content) {
        self.ad = ad
        self.content = content
    }

    public var body: some View {
        NativeAdHostingView(ad: ad, content: content)
    }
}

/// Collects the UIKit views backing each SwiftUI asset component and wires
/// them to the `GADNativeAdView` outlets before associating the native ad.
@MainActor
final class NativeAdAssetRegistry {
    weak var adView: GoogleMobileAds.NativeAdView?
    var nativeAd: GoogleMobileAds.NativeAd?

    private struct WeakView {
        weak var view: UIView?
    }

    private var assetViews: [NativeAdAssetKind: WeakView] = [:]
    private weak var mediaView: GoogleMobileAds.MediaView?
    private var applyScheduled = false

    func register(_ view: UIView, for kind: NativeAdAssetKind) {
        guard assetViews[kind]?.view !== view else { return }
        assetViews[kind] = WeakView(view: view)
        setNeedsApply()
    }

    func unregister(_ view: UIView, for kind: NativeAdAssetKind) {
        guard assetViews[kind]?.view === view else { return }
        assetViews[kind] = nil
        setNeedsApply()
    }

    func register(mediaView view: GoogleMobileAds.MediaView) {
        guard mediaView !== view else { return }
        mediaView = view
        setNeedsApply()
    }

    /// Coalesces outlet updates so the ad is (re)associated once per runloop
    /// turn, after every asset proxy in the layout has registered itself.
    func setNeedsApply() {
        guard !applyScheduled else { return }
        applyScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.apply()
        }
    }

    private func apply() {
        applyScheduled = false
        guard let adView else { return }
        adView.headlineView = assetViews[.headline]?.view
        adView.callToActionView = assetViews[.callToAction]?.view
        adView.iconView = assetViews[.icon]?.view
        adView.bodyView = assetViews[.body]?.view
        adView.storeView = assetViews[.store]?.view
        adView.priceView = assetViews[.price]?.view
        adView.imageView = assetViews[.image]?.view
        adView.starRatingView = assetViews[.starRating]?.view
        adView.advertiserView = assetViews[.advertiser]?.view
        adView.mediaView = mediaView
        // Must come after the outlets are wired up, otherwise the SDK won't
        // attribute impressions/clicks to the asset views.
        adView.nativeAd = nativeAd
    }
}

struct NativeAdAssetRegistryKey: EnvironmentKey {
    static let defaultValue: NativeAdAssetRegistry? = nil
}

extension EnvironmentValues {
    var nativeAdAssetRegistry: NativeAdAssetRegistry? {
        get { self[NativeAdAssetRegistryKey.self] }
        set { self[NativeAdAssetRegistryKey.self] = newValue }
    }
}

struct NativeAdHostingView<Content: View>: UIViewRepresentable {
    let ad: GoogleMobileAds.NativeAd
    let content: (NativeAdAssets) -> Content

    @MainActor
    final class Coordinator {
        let registry = NativeAdAssetRegistry()
        var hostingController: UIHostingController<AnyView>?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GoogleMobileAds.NativeAdView {
        let adView = GoogleMobileAds.NativeAdView()
        let registry = context.coordinator.registry
        registry.adView = adView

        let host = UIHostingController(rootView: rootView(registry: registry))
        host.view.backgroundColor = .clear
        if #available(iOS 16.0, *) {
            host.sizingOptions = .intrinsicContentSize
        }
        if #available(iOS 16.4, *) {
            host.safeAreaRegions = []
        }
        host.view.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: adView.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
        ])
        context.coordinator.hostingController = host
        return adView
    }

    func updateUIView(_ adView: GoogleMobileAds.NativeAdView, context: Context) {
        let registry = context.coordinator.registry
        registry.nativeAd = ad
        context.coordinator.hostingController?.rootView = rootView(registry: registry)
        registry.setNeedsApply()
    }

    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize,
                      uiView: GoogleMobileAds.NativeAdView,
                      context: Context) -> CGSize? {
        guard let host = context.coordinator.hostingController else { return nil }
        let target = CGSize(width: proposal.width ?? UIView.layoutFittingExpandedSize.width,
                            height: proposal.height ?? UIView.layoutFittingExpandedSize.height)
        var size = host.sizeThatFits(in: target)
        if let width = proposal.width { size.width = width }
        if let height = proposal.height { size.height = height }
        return size
    }

    private func rootView(registry: NativeAdAssetRegistry) -> AnyView {
        AnyView(
            content(NativeAdAssets(ad: ad))
                .environment(\.nativeAdAssetRegistry, registry)
        )
    }
}
