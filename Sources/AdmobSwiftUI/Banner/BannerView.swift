//
//  BannerView.swift
//
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

/// A SwiftUI banner ad view that sizes itself to the ad it displays.
///
/// The view reserves the correct height automatically: anchored styles reserve
/// the computed adaptive height as soon as the width is known (before the ad
/// loads), and all styles update to the actual rendered height once the ad
/// arrives. No external `.frame(height:)` is required.
public struct BannerView: View {
    private let adUnitID: String
    private let style: BannerViewStyle
    private let onAdEvent: (@MainActor (BannerAdEvent) -> Void)?
    @State private var adHeight: CGFloat

    /// - Parameters:
    ///   - adUnitID: The banner ad unit ID. Defaults to the environment-aware ID.
    ///   - style: Display style. See ``BannerViewStyle``.
    ///   - onAdEvent: Optional closure receiving ``BannerAdEvent`` lifecycle
    ///     events (load success/failure, impression, click, screen presentation).
    public init(
        adUnitID: String = AdmobSwiftUI.AdUnitIDs.banner,
        style: BannerViewStyle = .anchored,
        onAdEvent: (@MainActor (BannerAdEvent) -> Void)? = nil
    ) {
        self.adUnitID = adUnitID
        self.style = style
        self.onAdEvent = onAdEvent
        // Placeholder until the real adaptive height is known (anchored: as
        // soon as the width is measured; inline: when the ad loads).
        _adHeight = State(initialValue: 50)
    }

    public var body: some View {
        BannerViewRepresentable(
            adUnitID: adUnitID,
            style: style,
            adHeight: $adHeight,
            onAdEvent: onAdEvent
        )
        .frame(height: adHeight)
    }
}

struct BannerViewRepresentable: UIViewControllerRepresentable {
    let adUnitID: String
    let style: BannerViewStyle
    @Binding var adHeight: CGFloat
    let onAdEvent: (@MainActor (BannerAdEvent) -> Void)?
    @State private var viewWidth: CGFloat = .zero
    @State private var currentAdSize: AdSize?

    func makeUIViewController(context: Context) -> some UIViewController {
        let bannerViewController = BannerViewController()
        // The banner view lives on the coordinator: the representable struct is
        // recreated on every parent render, so an instance stored here would be
        // a fresh, detached view by the time updateUIViewController runs.
        let bannerView = context.coordinator.bannerView
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator
        bannerViewController.view.addSubview(bannerView)
        bannerViewController.delegate = context.coordinator

        return bannerViewController
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        context.coordinator.parent = self
        AdmobSwiftUI.log("Banner view width updated: \(viewWidth)", level: .debug)
        guard viewWidth != .zero else { return }

        // Only reload if size actually changed
        let newAdSize: AdSize = switch style {
        case .anchored, .collapsible:
            // SDK 13: large anchored adaptive banner (50-150pt tall, supports video demand)
            largeAnchoredAdaptiveBanner(width: viewWidth)
        case .inline(let maxHeight):
            if let maxHeight {
                inlineAdaptiveBanner(width: viewWidth, maxHeight: maxHeight)
            } else {
                currentOrientationInlineAdaptiveBanner(width: viewWidth)
            }
        }
        if currentAdSize == nil || !isAdSizeEqualToSize(size1: currentAdSize!, size2: newAdSize) {
            DispatchQueue.main.async {
                self.currentAdSize = newAdSize
                // Anchored heights are exact once the width is known, so the
                // layout can be reserved before the ad loads. The inline size's
                // height is only an upper bound — wait for didReceive instead.
                if case .inline(_) = style {} else {
                    self.adHeight = newAdSize.size.height
                }
            }
            let bannerView = context.coordinator.bannerView
            bannerView.adSize = newAdSize
            let request = GoogleMobileAds.Request()
            if case .collapsible(let placement) = style {
                let extras = Extras()
                extras.additionalParameters = ["collapsible": placement.rawValue]
                request.register(extras)
            }
            AdmobSwiftUI.log("Loading banner ad with size: \(newAdSize.size), style: \(style)", level: .debug)
            bannerView.load(request)
        }
    }

    @MainActor
    class Coordinator: NSObject, BannerViewControllerWidthDelegate, GoogleMobileAds.BannerViewDelegate {
        let bannerView = GoogleMobileAds.BannerView()
        var parent: BannerViewRepresentable

        init(_ parent: BannerViewRepresentable) {
            self.parent = parent
        }

        // MARK: - BannerViewControllerWidthDelegate methods

        func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            // Defer the state mutation out of the current view update cycle.
            Task { @MainActor in
                self.parent.viewWidth = width
            }
        }

        // MARK: - GoogleMobileAds.BannerViewDelegate methods

        public func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            let adSize = bannerView.adSize.size
            AdmobSwiftUI.log("Banner ad received successfully, size: \(adSize)", level: .debug)
            Task { @MainActor in
                self.parent.adHeight = adSize.height
                self.parent.onAdEvent?(.didReceive(adSize: adSize))
            }
        }

        public func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            AdmobSwiftUI.log("Banner ad failed to load: \(error.localizedDescription)", level: .error)
            Task { @MainActor in
                self.parent.onAdEvent?(.didFailToReceive(error: error))
            }
        }

        public func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad impression recorded", level: .debug)
            Task { @MainActor in
                self.parent.onAdEvent?(.didRecordImpression)
            }
        }

        public func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad click recorded", level: .debug)
            Task { @MainActor in
                self.parent.onAdEvent?(.didRecordClick)
            }
        }

        public func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad will present screen", level: .debug)
            Task { @MainActor in
                self.parent.onAdEvent?(.willPresentScreen)
            }
        }

        public func bannerViewWillDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad will dismiss screen", level: .debug)
            Task { @MainActor in
                self.parent.onAdEvent?(.willDismissScreen)
            }
        }

        public func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad did dismiss screen", level: .debug)
            Task { @MainActor in
                self.parent.onAdEvent?(.didDismissScreen)
            }
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        BannerView()
    }
}
