//
//  InterstitialAdCoordinator.swift
//
//
//  Created by minghui on 2023/6/13.
//

@preconcurrency import GoogleMobileAds
import SwiftUI

/// Coordinator for interstitial ads, conforming to ``FullScreenAdCoordinator``.
///
/// Load with `try await load()`, then present with `present(from:)` — or use
/// `loadAndPresent(from:)` to do both. Include an ``AdViewControllerRepresentable``
/// in the view hierarchy to obtain a presenting view controller.
@MainActor
public final class InterstitialAdCoordinator: NSObject, ObservableObject, FullScreenAdCoordinator {
    /// Current lifecycle state of the ad.
    @Published public private(set) var adState: AdState = .idle

    private var interstitial: GoogleMobileAds.InterstitialAd?
    private let adUnitID: String

    /// Creates a coordinator.
    /// - Parameter adUnitID: The interstitial ad unit ID. Defaults to the
    ///   environment-appropriate ID from ``AdmobSwiftUI/AdUnitIDs``.
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.interstitial) {
        self.adUnitID = adUnitID
        super.init()
    }

    // MARK: - FullScreenAdCoordinator

    /// Loads an interstitial ad, replacing any previously loaded one.
    /// A call made while another load is in flight is ignored.
    /// - Throws: ``AdmobSwiftUIError/adLoadFailed(_:)`` if the request fails.
    public func load() async throws {
        guard adState != .loading else {
            AdmobSwiftUI.log("Interstitial ad is already loading, request ignored", level: .debug)
            return
        }
        clean()
        adState = .loading
        do {
            let ad = try await GoogleMobileAds.InterstitialAd.load(with: adUnitID, request: GoogleMobileAds.Request())
            ad.fullScreenContentDelegate = self
            interstitial = ad
            adState = .ready
            AdmobSwiftUI.log("Interstitial ad loaded successfully", level: .debug)
        } catch {
            adState = .idle
            AdmobSwiftUI.log("Failed to load interstitial ad: \(error.localizedDescription)", level: .error)
            throw AdmobSwiftUIError.adLoadFailed(error)
        }
    }

    /// Presents the loaded interstitial ad.
    /// - Throws: ``AdmobSwiftUIError/adNotLoaded`` if no ad is ready.
    public func present(from viewController: UIViewController) throws {
        guard let interstitial else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        adState = .presenting
        interstitial.present(from: viewController)
    }

    // MARK: - Private

    private func clean() {
        interstitial?.fullScreenContentDelegate = nil
        interstitial = nil
        adState = .idle
    }
}

// MARK: - GADFullScreenContentDelegate
// SDK callbacks are not guaranteed to arrive on the main thread,
// so conform with nonisolated methods and hop back to the main actor.
extension InterstitialAdCoordinator: GoogleMobileAds.FullScreenContentDelegate {
    nonisolated public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        Task { @MainActor in
            self.clean()
        }
    }

    nonisolated public func ad(_ ad: GoogleMobileAds.FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            AdmobSwiftUI.log("Failed to present interstitial ad: \(message)", level: .error)
            self.clean()
        }
    }
}

// MARK: - Deprecated v2 API (will be removed in 4.0)
extension InterstitialAdCoordinator {
    /// Fire-and-forget load. Replaced by `try await load()`.
    @available(*, deprecated, renamed: "load()", message: "Use `try await load()` instead. Will be removed in 4.0.")
    public func loadAd() {
        Task { try? await load() }
    }

    /// Presents the loaded ad. Replaced by ``present(from:)``.
    @available(*, deprecated, renamed: "present(from:)", message: "Use `present(from:)` instead. Will be removed in 4.0.")
    public func showAd(from viewController: UIViewController) throws {
        try present(from: viewController)
    }

    /// Loads and returns the raw SDK ad object. Replaced by ``load()`` + ``present(from:)``.
    @available(*, deprecated, message: "Use `load()` and `present(from:)` instead. Will be removed in 4.0.")
    public func loadInterstitialAd() async throws -> GoogleMobileAds.InterstitialAd {
        try await load()
        guard let ad = interstitial else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        return ad
    }
}

// MARK: - Usage Example
/*
struct SampleView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    @StateObject private var interstitialAdCoordinator = InterstitialAdCoordinator()

    var body: some View {
        VStack {
            Text("Content View")

            Button("Show Interstitial Ad") {
                Task {
                    do {
                        try await interstitialAdCoordinator.loadAndPresent(
                            from: adViewControllerRepresentable.viewController
                        )
                    } catch {
                        print("Failed to show interstitial ad: \(error)")
                    }
                }
            }
        }
        .background {
            // Add the adViewControllerRepresentable to the background so it
            // does not influence the placement of other views in the view hierarchy.
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}
*/
