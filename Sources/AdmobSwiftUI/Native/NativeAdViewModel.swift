//
//  SwiftUIView.swift
//
//
//  Created by minghui on 2023/6/14.
//

import SwiftUI
@preconcurrency import GoogleMobileAds

/// Loads native ads and publishes them for ``NativeAdView`` /
/// ``AdmobNativeAdContainer``. Loaded ads are cached per ad unit ID and shared
/// across view model instances, with requests throttled by ``requestInterval``.
@MainActor
public class NativeAdViewModel: NSObject, ObservableObject {
    /// The most recently loaded (or cached) native ad; `nil` until a load succeeds.
    @Published public var nativeAd: GoogleMobileAds.NativeAd?
    /// Whether an ad request is currently in flight.
    @Published public var isLoading: Bool = false
    private var adLoader: GoogleMobileAds.AdLoader!
    private var adUnitID: String
    private var loadContinuation: CheckedContinuation<Void, any Error>?
    /// Minimum interval (seconds) between ad requests for the same ad unit;
    /// `load()` calls inside the window return the cached ad instead.
    public var requestInterval: Int
    // Shared across view model instances; isolated to the main actor.
    private static let cache = AdCache<GoogleMobileAds.NativeAd>(
        maxSize: AdmobSwiftUI.Constants.nativeAdCacheMaxSize
    )

    /// Creates a view model, picking up any cached ad for the ad unit.
    /// - Parameters:
    ///   - adUnitID: The native ad unit ID. Defaults to the
    ///     environment-appropriate ID from ``AdmobSwiftUI/AdUnitIDs``.
    ///   - requestInterval: Minimum interval (seconds) between requests.
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.native,
                requestInterval: Int = AdmobSwiftUI.Constants.nativeAdDefaultRequestInterval) {
        self.adUnitID = adUnitID
        self.requestInterval = requestInterval
        super.init()

        self.nativeAd = Self.cache.value(for: adUnitID)
    }

    /// Loads a native ad and suspends until the request finishes.
    ///
    /// Requests made within `requestInterval` of the previous one (while a
    /// cached ad exists) or while another request is in flight return
    /// immediately without error.
    /// - Throws: ``AdmobSwiftUIError/adLoadFailed(_:)`` if the request fails.
    public func load() async throws {
        let now = Date()

        if Self.cache.hasFreshValue(for: adUnitID, within: TimeInterval(requestInterval), now: now) {
            AdmobSwiftUI.log("The last request was made less than \(requestInterval) seconds ago. New request is canceled.", level: .debug)
            nativeAd = Self.cache.value(for: adUnitID)
            return
        }

        guard !isLoading else {
            AdmobSwiftUI.log("Previous request is still loading, new request is canceled.", level: .debug)
            return
        }

        isLoading = true
        Self.cache.markRequested(adUnitID, at: now)

        let adViewOptions = GoogleMobileAds.NativeAdViewAdOptions()
        adViewOptions.preferredAdChoicesPosition = .topRightCorner
        adLoader = GoogleMobileAds.AdLoader(adUnitID: adUnitID, rootViewController: nil, adTypes: [.native], options: [adViewOptions])
        adLoader.delegate = self

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            loadContinuation = continuation
            adLoader.load(GoogleMobileAds.Request())
        }
    }

    // MARK: - Loader result handling (main actor)

    private func handleLoaded(_ nativeAd: GoogleMobileAds.NativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
        self.isLoading = false

        Self.cache.store(nativeAd, for: adUnitID)
        nativeAd.mediaContent.videoController.delegate = self

        loadContinuation?.resume()
        loadContinuation = nil
    }

    private func handleLoadFailure(_ error: any Error) {
        self.isLoading = false
        loadContinuation?.resume(throwing: AdmobSwiftUIError.adLoadFailed(error))
        loadContinuation = nil
    }
}

// MARK: - Deprecated v2 API (will be removed in 4.0)
extension NativeAdViewModel {
    /// Fire-and-forget load. Replaced by `try await load()`.
    @available(*, deprecated, renamed: "load()", message: "Use `try await load()` instead. Will be removed in 4.0.")
    public func refreshAd() {
        Task { try? await load() }
    }
}

// MARK: - GADNativeAdLoaderDelegate
// SDK callbacks are not guaranteed to arrive on the main thread,
// so conform with nonisolated methods and hop back to the main actor.
extension NativeAdViewModel: GoogleMobileAds.NativeAdLoaderDelegate {
    nonisolated public func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didReceive nativeAd: GoogleMobileAds.NativeAd) {
        Task { @MainActor in
            self.handleLoaded(nativeAd)
        }
    }

    nonisolated public func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didFailToReceiveAdWithError error: any Error) {
        AdmobSwiftUI.log("Ad loader failed with error: \(error.localizedDescription)", level: .error)
        Task { @MainActor in
            self.handleLoadFailure(error)
        }
    }
}

extension NativeAdViewModel: GoogleMobileAds.VideoControllerDelegate {
    // GADVideoControllerDelegate methods
    nonisolated public func videoControllerDidPlayVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // begins playing the ad.
    }

    nonisolated public func videoControllerDidPauseVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // pauses the ad.
    }

    nonisolated public func videoControllerDidEndVideoPlayback(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // stops playing the ad.
    }

    nonisolated public func videoControllerDidMuteVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // mutes the ad.
    }

    nonisolated public func videoControllerDidUnmuteVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // unmutes the ad.
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: GoogleMobileAds.NativeAdDelegate {
    nonisolated public func nativeAdDidRecordClick(_ nativeAd: GoogleMobileAds.NativeAd) {
        AdmobSwiftUI.log("\(#function) called", level: .debug)
    }

    nonisolated public func nativeAdDidRecordImpression(_ nativeAd: GoogleMobileAds.NativeAd) {
        AdmobSwiftUI.log("\(#function) called", level: .debug)
    }

    nonisolated public func nativeAdWillPresentScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        AdmobSwiftUI.log("\(#function) called", level: .debug)
    }

    nonisolated public func nativeAdWillDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        AdmobSwiftUI.log("\(#function) called", level: .debug)
    }

    nonisolated public func nativeAdDidDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        AdmobSwiftUI.log("\(#function) called", level: .debug)
    }
}
