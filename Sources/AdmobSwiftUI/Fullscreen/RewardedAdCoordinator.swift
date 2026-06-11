//
//  RewardedAdCoordinator.swift
//
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
@preconcurrency import GoogleMobileAds

/// Coordinator for rewarded and rewarded interstitial ads.
///
/// Follows the same `adState` / `load()` shape as ``FullScreenAdCoordinator``,
/// but `present(from:)` suspends until the user earns the reward and returns
/// an ``AdReward`` directly, so it does not conform to the protocol.
@MainActor
public final class RewardedAdCoordinator: NSObject, ObservableObject {

    /// Which rewarded format to load.
    public enum AdKind: Sendable {
        /// A standard rewarded ad (user opts in to watch).
        case rewarded
        /// A rewarded interstitial ad (shown at natural transitions).
        case rewardedInterstitial
    }

    /// Current lifecycle state of the ad.
    @Published public private(set) var adState: AdState = .idle

    /// Whether an ad is loaded and can be presented right now.
    public var isReady: Bool { adState == .ready }

    private var rewardedAd: GoogleMobileAds.RewardedAd?
    private var rewardedInterstitialAd: GoogleMobileAds.RewardedInterstitialAd?
    private let adUnitID: String
    private let interstitialAdUnitID: String
    private var rewardContinuation: CheckedContinuation<AdReward, any Error>?

    /// Creates a coordinator.
    /// - Parameters:
    ///   - adUnitID: Ad unit ID used for ``AdKind/rewarded`` loads.
    ///   - interstitialAdUnitID: Ad unit ID used for ``AdKind/rewardedInterstitial`` loads.
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.rewarded,
                interstitialAdUnitID: String = AdmobSwiftUI.AdUnitIDs.rewardedInterstitial) {
        self.adUnitID = adUnitID
        self.interstitialAdUnitID = interstitialAdUnitID
    }

    // MARK: - Async/await API

    /// Loads an ad of the given kind, replacing any previously loaded one.
    /// A call made while another load is in flight is ignored.
    /// - Throws: ``AdmobSwiftUIError/adLoadFailed(_:)`` if the request fails.
    public func load(_ kind: AdKind = .rewarded) async throws {
        guard adState != .loading else {
            AdmobSwiftUI.log("Rewarded ad is already loading, request ignored", level: .debug)
            return
        }
        clean()
        adState = .loading
        do {
            switch kind {
            case .rewarded:
                let ad = try await GoogleMobileAds.RewardedAd.load(with: adUnitID, request: GoogleMobileAds.Request())
                ad.fullScreenContentDelegate = self
                rewardedAd = ad
            case .rewardedInterstitial:
                let ad = try await GoogleMobileAds.RewardedInterstitialAd.load(with: interstitialAdUnitID, request: GoogleMobileAds.Request())
                ad.fullScreenContentDelegate = self
                rewardedInterstitialAd = ad
            }
            adState = .ready
            AdmobSwiftUI.log("Rewarded ad loaded successfully", level: .debug)
        } catch {
            adState = .idle
            AdmobSwiftUI.log("Failed to load rewarded ad: \(error.localizedDescription)", level: .error)
            throw AdmobSwiftUIError.adLoadFailed(error)
        }
    }

    /// Presents the loaded ad and suspends until the user earns the reward.
    /// - Returns: The earned ``AdReward``.
    /// - Throws: ``AdmobSwiftUIError/adNotLoaded`` if no ad is ready,
    ///   ``AdmobSwiftUIError/rewardNotEarned`` if the user dismisses the ad
    ///   before earning the reward.
    public func present(from viewController: UIViewController) async throws -> AdReward {
        guard adState == .ready else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        adState = .presenting
        return try await withCheckedThrowingContinuation { continuation in
            rewardContinuation = continuation
            if let rewardedAd {
                rewardedAd.present(from: viewController) { [weak self] in
                    guard let self else { return }
                    let reward = rewardedAd.adReward
                    self.resumeReward(.success(AdReward(amount: reward.amount.intValue, type: reward.type)))
                }
            } else if let rewardedInterstitialAd {
                rewardedInterstitialAd.present(from: viewController) { [weak self] in
                    guard let self else { return }
                    let reward = rewardedInterstitialAd.adReward
                    self.resumeReward(.success(AdReward(amount: reward.amount.intValue, type: reward.type)))
                }
            } else {
                resumeReward(.failure(AdmobSwiftUIError.adNotLoaded))
            }
        }
    }

    /// Loads an ad if needed, presents it, and suspends until the reward is earned.
    @discardableResult
    public func loadAndPresent(_ kind: AdKind = .rewarded, from viewController: UIViewController) async throws -> AdReward {
        if !isReady {
            try await load(kind)
        }
        return try await present(from: viewController)
    }

    // MARK: - Private

    private func resumeReward(_ result: Result<AdReward, any Error>) {
        rewardContinuation?.resume(with: result)
        rewardContinuation = nil
    }

    private func clean() {
        // Never leak a suspended caller: if an ad is torn down while a
        // present(from:) is still pending, fail it explicitly.
        resumeReward(.failure(AdmobSwiftUIError.rewardNotEarned))
        rewardedInterstitialAd?.fullScreenContentDelegate = nil
        rewardedAd?.fullScreenContentDelegate = nil
        rewardedInterstitialAd = nil
        rewardedAd = nil
        adState = .idle
    }
}

// MARK: - GADFullScreenContentDelegate
// SDK callbacks are not guaranteed to arrive on the main thread,
// so conform with nonisolated methods and hop back to the main actor.
extension RewardedAdCoordinator: GoogleMobileAds.FullScreenContentDelegate {
    nonisolated public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        Task { @MainActor in
            self.clean()
        }
    }

    nonisolated public func ad(_ ad: GoogleMobileAds.FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            AdmobSwiftUI.log("Failed to present rewarded ad: \(message)", level: .error)
            self.resumeReward(.failure(AdmobSwiftUIError.presentationFailed(message)))
            self.clean()
        }
    }
}

// MARK: - Deprecated v2 API (will be removed in 4.0)
extension RewardedAdCoordinator {
    /// v2 initializer kept for source compatibility. Replaced by `init(adUnitID:interstitialAdUnitID:)`.
    @available(*, deprecated, renamed: "init(adUnitID:interstitialAdUnitID:)", message: "Use `init(adUnitID:interstitialAdUnitID:)` instead. Will be removed in 4.0.")
    public convenience init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.rewarded, InterstitialID: String) {
        self.init(adUnitID: adUnitID, interstitialAdUnitID: InterstitialID)
    }

    /// Fire-and-forget load. Replaced by `try await load(_:)`.
    @available(*, deprecated, renamed: "load(_:)", message: "Use `try await load()` instead. Will be removed in 4.0.")
    public func loadAd() {
        Task { try? await load() }
    }

    /// Loads and returns the raw SDK ad object. Replaced by ``load(_:)`` + ``present(from:)``.
    @available(*, deprecated, message: "Use `load()` and `present(from:)` instead. Will be removed in 4.0.")
    public func loadRewardedAd() async throws -> GoogleMobileAds.RewardedAd {
        try await load(.rewarded)
        guard let ad = rewardedAd else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        return ad
    }

    /// Loads and returns the raw SDK ad object. Replaced by ``load(_:)`` + ``present(from:)``.
    @available(*, deprecated, message: "Use `load(.rewardedInterstitial)` and `present(from:)` instead. Will be removed in 4.0.")
    public func loadInterstitialAd() async throws -> GoogleMobileAds.RewardedInterstitialAd {
        try await load(.rewardedInterstitial)
        guard let ad = rewardedInterstitialAd else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        return ad
    }

    /// Callback-based presentation. Replaced by `try await present(from:)`, which returns the ``AdReward``.
    @available(*, deprecated, message: "Use `try await present(from:)` instead. Will be removed in 4.0.")
    public func showAd(from viewController: UIViewController, userDidEarnRewardHandler completion: @escaping (Int) -> Void) {
        guard let rewardedAd else {
            AdmobSwiftUI.log("Rewarded ad wasn't ready", level: .warning)
            return
        }
        adState = .presenting
        rewardedAd.present(from: viewController, userDidEarnRewardHandler: {
            let reward = rewardedAd.adReward
            AdmobSwiftUI.log("Reward amount: \(reward.amount)", level: .debug)
            completion(reward.amount.intValue)
        })
    }
}

// MARK: - Usage Example
/*
struct RewardSampleView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    @StateObject private var rewardCoordinator = RewardedAdCoordinator()

    var body: some View {
        Button("Watch ad to earn reward") {
            Task {
                do {
                    let reward = try await rewardCoordinator.loadAndPresent(
                        from: adViewControllerRepresentable.viewController
                    )
                    print("Earned \(reward.amount) \(reward.type)")
                } catch {
                    print("No reward: \(error)")
                }
            }
        }
        .background {
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}
*/
