//
//  SwiftUIView.swift
//
//
//  Created by minghui on 2023/6/14.
//

import SwiftUI
@preconcurrency import GoogleMobileAds

@MainActor
public class NativeAdViewModel: NSObject, ObservableObject {
    @Published public var nativeAd: GoogleMobileAds.NativeAd?
    @Published public var isLoading: Bool = false
    private var adLoader: GoogleMobileAds.AdLoader!
    private var adUnitID: String
    private var lastRequestTime: Date?
    private var loadContinuation: CheckedContinuation<Void, any Error>?
    public var requestInterval: Int
    private static let maxCacheSize = AdmobSwiftUI.Constants.nativeAdCacheMaxSize
    // Cache is isolated to the main actor along with the rest of the class.
    private static var cachedAds: [String: GoogleMobileAds.NativeAd] = [:]
    private static var lastRequestTimes: [String: Date] = [:]

    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.native,
                requestInterval: Int = AdmobSwiftUI.Constants.nativeAdDefaultRequestInterval) {
        self.adUnitID = adUnitID
        self.requestInterval = requestInterval
        super.init()

        self.nativeAd = NativeAdViewModel.cachedAds[adUnitID]
        self.lastRequestTime = NativeAdViewModel.lastRequestTimes[adUnitID]
    }

    /// Loads a native ad and suspends until the request finishes.
    ///
    /// Requests made within `requestInterval` of the previous one (while a
    /// cached ad exists) or while another request is in flight return
    /// immediately without error.
    /// - Throws: ``AdmobSwiftUIError/adLoadFailed(_:)`` if the request fails.
    public func load() async throws {
        let now = Date()

        if nativeAd != nil, let lastRequest = lastRequestTime, now.timeIntervalSince(lastRequest) < Double(requestInterval) {
            AdmobSwiftUI.log("The last request was made less than \(requestInterval / 60) minutes ago. New request is canceled.", level: .debug)
            return
        }

        guard !isLoading else {
            AdmobSwiftUI.log("Previous request is still loading, new request is canceled.", level: .debug)
            return
        }

        isLoading = true
        lastRequestTime = now
        NativeAdViewModel.lastRequestTimes[adUnitID] = now

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

        // Cache the ad safely with size management
        Self.setCachedAd(nativeAd, for: adUnitID)
        nativeAd.mediaContent.videoController.delegate = self

        loadContinuation?.resume()
        loadContinuation = nil
    }

    private func handleLoadFailure(_ error: any Error) {
        self.isLoading = false
        loadContinuation?.resume(throwing: AdmobSwiftUIError.adLoadFailed(error))
        loadContinuation = nil
    }

    // MARK: - Cache Management
    private static func setCachedAd(_ ad: GoogleMobileAds.NativeAd, for key: String) {
        // Clean cache if it's getting too large
        cleanupCacheIfNeeded()

        cachedAds[key] = ad
        lastRequestTimes[key] = Date()
    }

    private static func cleanupCacheIfNeeded() {
        guard cachedAds.count >= maxCacheSize else { return }

        // Remove oldest cached ad
        if let oldestKey = lastRequestTimes.min(by: { $0.value < $1.value })?.key {
            cachedAds.removeValue(forKey: oldestKey)
            lastRequestTimes.removeValue(forKey: oldestKey)
        }
    }
}

// MARK: - Deprecated v2 API (will be removed in 4.0)
extension NativeAdViewModel {
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
