//
//  AppOpenAdCoordinator.swift
//
//
//  Created by minghui on 2023/6/13.
//

@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
public final class AppOpenAdCoordinator: NSObject, ObservableObject, FullScreenAdCoordinator {
    @Published public private(set) var adState: AdState = .idle

    /// When enabled, the coordinator automatically reloads an ad after the
    /// presented one is dismissed and whenever the app returns to the
    /// foreground without a usable ad — replacing the hand-written
    /// scenePhase reload boilerplate. Pair it with ``presentIfAvailable(from:)``.
    public var autoReloadsOnForeground: Bool = false {
        didSet { updateForegroundObserver() }
    }

    private var appOpenAd: GoogleMobileAds.AppOpenAd?
    private let adUnitID: String
    private var loadTime: Date?
    private var foregroundObserver: (any NSObjectProtocol)?

    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.appOpen) {
        // Validate ad unit ID
        guard !adUnitID.isEmpty else {
            fatalError("AdmobSwiftUI: Ad unit ID cannot be empty")
        }

        if adUnitID.hasPrefix("your-") {
            AdmobSwiftUI.log("Warning: Using placeholder ad unit ID. Replace with your actual ad unit ID before release.", level: .warning)
        }

        self.adUnitID = adUnitID
        super.init()
    }

    deinit {
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
    }

    // MARK: - FullScreenAdCoordinator

    public var isReady: Bool {
        adState == .ready && !isAdExpired
    }

    public func load() async throws {
        guard adState != .loading else {
            AdmobSwiftUI.log("App open ad is already loading, request ignored", level: .debug)
            return
        }
        clean()
        adState = .loading
        do {
            let ad = try await GoogleMobileAds.AppOpenAd.load(with: adUnitID, request: GoogleMobileAds.Request())
            ad.fullScreenContentDelegate = self
            appOpenAd = ad
            loadTime = Date()
            adState = .ready
            AdmobSwiftUI.log("App open ad loaded successfully", level: .debug)
        } catch {
            adState = .idle
            AdmobSwiftUI.log("Failed to load app open ad: \(error.localizedDescription)", level: .error)
            throw AdmobSwiftUIError.adLoadFailed(error)
        }
    }

    public func present(from viewController: UIViewController) throws {
        guard let appOpenAd else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        guard !isAdExpired else {
            clean()
            throw AdmobSwiftUIError.adExpired
        }
        adState = .presenting
        appOpenAd.present(from: viewController)
    }

    /// Failure-tolerant presentation for scene-phase call sites: presents the
    /// ad if one is ready, otherwise just logs and (when nothing is in flight)
    /// kicks off a reload so the next foreground transition has an ad.
    /// - Parameter viewController: Presenting view controller; pass `nil` to
    ///   let the SDK present from the key window's root view controller.
    public func presentIfAvailable(from viewController: UIViewController? = nil) {
        guard isReady, let appOpenAd else {
            AdmobSwiftUI.log("App open ad not ready to present (state: \(adState))", level: .debug)
            if adState == .idle || (adState == .ready && isAdExpired) {
                reload()
            }
            return
        }
        adState = .presenting
        appOpenAd.present(from: viewController)
    }

    // MARK: - Private

    private var isAdExpired: Bool {
        guard let loadTime else { return true }
        return Date().timeIntervalSince(loadTime) > AdmobSwiftUI.Constants.appOpenAdExpirationInterval
    }

    private func clean() {
        appOpenAd?.fullScreenContentDelegate = nil
        appOpenAd = nil
        loadTime = nil
        adState = .idle
    }

    private func reload() {
        Task { try? await load() }
    }

    private func updateForegroundObserver() {
        if autoReloadsOnForeground, foregroundObserver == nil {
            foregroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.autoReloadsOnForeground, !self.isReady, self.adState == .idle else { return }
                    self.reload()
                }
            }
        } else if !autoReloadsOnForeground, let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
    }
}

// MARK: - GADFullScreenContentDelegate
// SDK callbacks are not guaranteed to arrive on the main thread,
// so conform with nonisolated methods and hop back to the main actor.
extension AppOpenAdCoordinator: GoogleMobileAds.FullScreenContentDelegate {
    nonisolated public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        Task { @MainActor in
            self.clean()
            if self.autoReloadsOnForeground {
                self.reload()
            }
        }
    }

    nonisolated public func ad(_ ad: GoogleMobileAds.FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            AdmobSwiftUI.log("Failed to present app open ad: \(message)", level: .error)
            self.clean()
        }
    }

    nonisolated public func adWillPresentFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        AdmobSwiftUI.log("App open ad will present", level: .debug)
    }

    nonisolated public func adDidRecordImpression(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        AdmobSwiftUI.log("App open ad did record impression", level: .debug)
    }
}

// MARK: - Deprecated v2 API (will be removed in 4.0)
extension AppOpenAdCoordinator {
    @available(*, deprecated, renamed: "isReady", message: "Use `isReady` instead. Will be removed in 4.0.")
    public var isAdAvailable: Bool {
        isReady
    }

    @available(*, deprecated, renamed: "load()", message: "Use `try await load()` instead. Will be removed in 4.0.")
    public func loadAd() {
        Task { try? await load() }
    }

    @available(*, deprecated, renamed: "present(from:)", message: "Use `present(from:)` or `presentIfAvailable(from:)` instead. Will be removed in 4.0.")
    public func showAd(from viewController: UIViewController) throws {
        try present(from: viewController)
    }

    @available(*, deprecated, message: "Use `load()` and `present(from:)` instead. Will be removed in 4.0.")
    public func loadAppOpenAd() async throws -> GoogleMobileAds.AppOpenAd {
        try await load()
        guard let ad = appOpenAd else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        return ad
    }

    @available(*, deprecated, message: "Use `load()` and `present(from:)` instead. Will be removed in 4.0.")
    public func loadAdAsync() async throws -> GoogleMobileAds.AppOpenAd {
        try await loadAppOpenAd()
    }
}

// MARK: - Usage Example
/*
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appOpenAdCoordinator = AppOpenAdCoordinator()

    var body: some View {
        Text("App Content")
            .onAppear {
                appOpenAdCoordinator.autoReloadsOnForeground = true
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    // Tolerates "no ad yet" — presents when ready, reloads otherwise.
                    appOpenAdCoordinator.presentIfAvailable()
                }
            }
    }
}
*/
