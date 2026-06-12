import XCTest
import GoogleMobileAds
@testable import AdmobSwiftUI

final class AdmobSwiftUITests: XCTestCase {

    func testAdmobSwiftUIVersionIsSemver() throws {
        // 驗證 semver 格式（major.minor.patch），不硬編碼版本號
        let semverPattern = #"^\d+\.\d+\.\d+$"#
        XCTAssertNotNil(
            AdmobSwiftUI.version.range(of: semverPattern, options: .regularExpression),
            "Version \"\(AdmobSwiftUI.version)\" is not a valid semver string"
        )
    }

    func testConfigurationInitialization() throws {
        let config = AdmobSwiftUI.Configuration()
        XCTAssertFalse(config.enableDebugMode)
        XCTAssertNil(config.testDeviceIdentifiers)
        XCTAssertNil(config.maxAdContentRating)
    }

    func testConfigurationWithDebugMode() throws {
        let config = AdmobSwiftUI.Configuration(enableDebugMode: true)
        XCTAssertTrue(config.enableDebugMode)
    }

    func testConfigurationWithCustomSettings() throws {
        let testDevices = ["device1", "device2"]
        let config = AdmobSwiftUI.Configuration(
            testDeviceIdentifiers: testDevices,
            maxAdContentRating: .general,
            enableDebugMode: false
        )
        XCTAssertEqual(config.testDeviceIdentifiers, testDevices)
        XCTAssertEqual(config.maxAdContentRating, .general)
        XCTAssertFalse(config.enableDebugMode)
    }

    func testAdmobSwiftUIErrorMessages() throws {
        XCTAssertEqual(AdmobSwiftUIError.adNotLoaded.errorDescription, "Ad is not loaded yet")
        XCTAssertEqual(AdmobSwiftUIError.sdkNotInitialized.errorDescription, "Google Mobile Ads SDK is not initialized")
        XCTAssertEqual(AdmobSwiftUIError.adExpired.errorDescription, "The loaded ad has expired and cannot be shown")

        let testError = NSError(domain: "Test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        XCTAssertEqual(AdmobSwiftUIError.adLoadFailed(testError).errorDescription, "Failed to load ad: Test error")
        XCTAssertEqual(AdmobSwiftUIError.presentationFailed("Test reason").errorDescription, "Failed to present ad: Test reason")
        XCTAssertEqual(AdmobSwiftUIError.invalidConfiguration("bad value").errorDescription, "Invalid configuration: bad value")
    }

    func testConstants() throws {
        XCTAssertEqual(AdmobSwiftUI.Constants.appOpenAdExpirationInterval, 4 * 60 * 60)
        XCTAssertEqual(AdmobSwiftUI.Constants.nativeAdCacheMaxSize, 10)
        XCTAssertEqual(AdmobSwiftUI.Constants.nativeAdDefaultRequestInterval, 60)
    }

    func testRewardNotEarnedErrorMessage() throws {
        XCTAssertEqual(
            AdmobSwiftUIError.rewardNotEarned.errorDescription,
            "The rewarded ad was dismissed before the reward was earned"
        )
    }
}

final class AdUnitIDsTests: XCTestCase {

    func testIsTestAdID() throws {
        XCTAssertTrue(AdmobSwiftUI.AdUnitIDs.isTestAdID(AdmobSwiftUI.AdUnitIDs.testBanner))
        XCTAssertTrue(AdmobSwiftUI.AdUnitIDs.isTestAdID(AdmobSwiftUI.AdUnitIDs.testAppOpen))
        XCTAssertFalse(AdmobSwiftUI.AdUnitIDs.isTestAdID("ca-app-pub-1234567890123456/1234567890"))
    }

    func testUseTestAdsInDebugBuild() throws {
        #if DEBUG
        XCTAssertTrue(AdmobSwiftUI.AdUnitIDs.useTestAds)
        XCTAssertEqual(AdmobSwiftUI.AdUnitIDs.banner, AdmobSwiftUI.AdUnitIDs.testBanner)
        XCTAssertEqual(AdmobSwiftUI.AdUnitIDs.interstitial, AdmobSwiftUI.AdUnitIDs.testInterstitial)
        XCTAssertEqual(AdmobSwiftUI.AdUnitIDs.rewarded, AdmobSwiftUI.AdUnitIDs.testRewarded)
        XCTAssertEqual(AdmobSwiftUI.AdUnitIDs.rewardedInterstitial, AdmobSwiftUI.AdUnitIDs.testRewardedInterstitial)
        XCTAssertEqual(AdmobSwiftUI.AdUnitIDs.native, AdmobSwiftUI.AdUnitIDs.testNative)
        XCTAssertEqual(AdmobSwiftUI.AdUnitIDs.appOpen, AdmobSwiftUI.AdUnitIDs.testAppOpen)
        #endif
    }

    func testValidateProductionAdsReportsPlaceholders() throws {
        // 套件預設的 production ID 都是 "your-" 開頭的佔位字串
        let missing = AdmobSwiftUI.AdUnitIDs.validateProductionAds()
        XCTAssertEqual(
            Set(missing),
            Set(["Banner", "Interstitial", "Rewarded", "Rewarded Interstitial", "Native", "App Open"])
        )
    }
}

@MainActor
final class CoordinatorInitializationTests: XCTestCase {

    func testInterstitialAdCoordinatorDefaultInit() throws {
        XCTAssertNotNil(InterstitialAdCoordinator())
    }

    func testInterstitialAdCoordinatorWithCustomAdUnit() throws {
        XCTAssertNotNil(InterstitialAdCoordinator(adUnitID: "test-interstitial-id"))
    }

    func testRewardedAdCoordinatorDefaultInit() throws {
        XCTAssertNotNil(RewardedAdCoordinator())
    }

    func testRewardedAdCoordinatorWithCustomAdUnits() throws {
        let coordinator = RewardedAdCoordinator(
            adUnitID: "test-rewarded-id",
            interstitialAdUnitID: "test-rewarded-interstitial-id"
        )
        XCTAssertNotNil(coordinator)
    }

    func testAppOpenAdCoordinatorDefaultInit() throws {
        let coordinator = AppOpenAdCoordinator()
        XCTAssertNotNil(coordinator)
        XCTAssertFalse(coordinator.isReady)
    }
}

@MainActor
final class FullScreenAdCoordinatorStateTests: XCTestCase {

    func testInterstitialInitialState() throws {
        let coordinator = InterstitialAdCoordinator()
        XCTAssertEqual(coordinator.adState, .idle)
        XCTAssertFalse(coordinator.isReady)
    }

    func testInterstitialPresentWithoutLoadThrowsAdNotLoaded() throws {
        let coordinator = InterstitialAdCoordinator()
        XCTAssertThrowsError(try coordinator.present(from: UIViewController())) { error in
            guard case AdmobSwiftUIError.adNotLoaded = error else {
                return XCTFail("Expected adNotLoaded, got \(error)")
            }
        }
        // A failed present must not leave the coordinator in a stuck state.
        XCTAssertEqual(coordinator.adState, .idle)
    }

    func testAppOpenInitialState() throws {
        let coordinator = AppOpenAdCoordinator()
        XCTAssertEqual(coordinator.adState, .idle)
        XCTAssertFalse(coordinator.isReady)
    }

    func testAppOpenPresentWithoutLoadThrowsAdNotLoaded() throws {
        let coordinator = AppOpenAdCoordinator()
        XCTAssertThrowsError(try coordinator.present(from: UIViewController())) { error in
            guard case AdmobSwiftUIError.adNotLoaded = error else {
                return XCTFail("Expected adNotLoaded, got \(error)")
            }
        }
        XCTAssertEqual(coordinator.adState, .idle)
    }

    func testAppOpenAutoReloadsOnForegroundToggle() throws {
        let coordinator = AppOpenAdCoordinator()
        XCTAssertFalse(coordinator.autoReloadsOnForeground)
        coordinator.autoReloadsOnForeground = true
        XCTAssertTrue(coordinator.autoReloadsOnForeground)
        coordinator.autoReloadsOnForeground = false
        XCTAssertFalse(coordinator.autoReloadsOnForeground)
    }

    func testRewardedInitialState() throws {
        let coordinator = RewardedAdCoordinator()
        XCTAssertEqual(coordinator.adState, .idle)
        XCTAssertFalse(coordinator.isReady)
    }

    func testRewardedPresentWithoutLoadThrowsAdNotLoaded() async throws {
        let coordinator = RewardedAdCoordinator()
        do {
            _ = try await coordinator.present(from: UIViewController())
            XCTFail("Expected present to throw")
        } catch {
            guard case AdmobSwiftUIError.adNotLoaded = error else {
                return XCTFail("Expected adNotLoaded, got \(error)")
            }
        }
        XCTAssertEqual(coordinator.adState, .idle)
    }

    func testAdRewardEquatable() throws {
        let reward = AdReward(amount: 10, type: "coins")
        XCTAssertEqual(reward, AdReward(amount: 10, type: "coins"))
        XCTAssertNotEqual(reward, AdReward(amount: 5, type: "coins"))
        XCTAssertEqual(reward.amount, 10)
        XCTAssertEqual(reward.type, "coins")
    }
}

@MainActor
final class NativeAdViewModelTests: XCTestCase {

    func testNativeAdViewModelInitialization() throws {
        let viewModel = NativeAdViewModel()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.requestInterval, 60)
    }

    func testNativeAdViewModelWithCustomInterval() throws {
        let viewModel = NativeAdViewModel(requestInterval: 300)
        XCTAssertEqual(viewModel.requestInterval, 300)
    }

    func testNativeAdViewModelWithCustomAdUnit() throws {
        XCTAssertNotNil(NativeAdViewModel(adUnitID: "custom-ad-unit-id"))
    }
}

final class BannerViewStyleTests: XCTestCase {

    func testCollapsiblePlacementRawValuesMatchAdMobParameters() throws {
        // Extras additionalParameters 的值必須是 "top" / "bottom"（Google 規格）
        XCTAssertEqual(BannerViewStyle.CollapsiblePlacement.top.rawValue, "top")
        XCTAssertEqual(BannerViewStyle.CollapsiblePlacement.bottom.rawValue, "bottom")
    }

    func testStyleEquatable() throws {
        XCTAssertEqual(BannerViewStyle.anchored, .anchored)
        XCTAssertEqual(BannerViewStyle.inline, .inline)
        XCTAssertEqual(
            BannerViewStyle.collapsible(placement: .bottom),
            .collapsible(placement: .bottom)
        )
        XCTAssertNotEqual(
            BannerViewStyle.collapsible(placement: .top),
            .collapsible(placement: .bottom)
        )
        XCTAssertNotEqual(BannerViewStyle.anchored, .inline)
    }

    func testInlineMaxHeight() throws {
        // 無參數簡寫等同 maxHeight: nil（源碼相容）
        XCTAssertEqual(BannerViewStyle.inline, .inline(maxHeight: nil))
        XCTAssertEqual(BannerViewStyle.inline(maxHeight: 150), .inline(maxHeight: 150))
        XCTAssertNotEqual(BannerViewStyle.inline(maxHeight: 150), .inline)
        XCTAssertNotEqual(BannerViewStyle.inline(maxHeight: 150), .inline(maxHeight: 120))
    }
}

@MainActor
final class BannerViewTests: XCTestCase {

    func testBannerViewInitWithAllStyles() throws {
        XCTAssertNotNil(BannerView(style: .anchored))
        XCTAssertNotNil(BannerView(style: .inline))
        XCTAssertNotNil(BannerView(style: .inline(maxHeight: 150)))
        XCTAssertNotNil(BannerView(style: .collapsible(placement: .top)))
        XCTAssertNotNil(BannerView(style: .collapsible(placement: .bottom)))
    }

    func testBannerViewInitWithAdEventClosure() throws {
        let view = BannerView(adUnitID: "custom-banner-id", style: .anchored) { _ in }
        XCTAssertNotNil(view)
    }
}

@MainActor
final class NativeAdViewStyleTests: XCTestCase {

    func testStyleCasesAreComplete() throws {
        XCTAssertEqual(NativeAdViewStyle.allCases, [.basic, .card, .banner, .largeBanner])
    }

    func testNativeAdViewInitWithAllStyles() throws {
        let viewModel = NativeAdViewModel()
        for style in NativeAdViewStyle.allCases {
            XCTAssertNotNil(NativeAdView(nativeViewModel: viewModel, style: style))
        }
    }
}

@MainActor
final class NativeAdAssetRegistryTests: XCTestCase {

    func testRegisterWiresOutletsToAdView() async throws {
        let registry = NativeAdAssetRegistry()
        let adView = GoogleMobileAds.NativeAdView()
        registry.adView = adView

        let headline = UIView()
        let cta = UIView()
        let icon = UIView()
        registry.register(headline, for: .headline)
        registry.register(cta, for: .callToAction)
        registry.register(icon, for: .icon)

        // apply() is coalesced onto the next main runloop turn.
        await Task.yield()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertIdentical(adView.headlineView, headline)
        XCTAssertIdentical(adView.callToActionView, cta)
        XCTAssertIdentical(adView.iconView, icon)
    }

    func testUnregisterClearsOutlet() async throws {
        let registry = NativeAdAssetRegistry()
        let adView = GoogleMobileAds.NativeAdView()
        registry.adView = adView

        let headline = UIView()
        registry.register(headline, for: .headline)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertIdentical(adView.headlineView, headline)

        registry.unregister(headline, for: .headline)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNil(adView.headlineView)
    }

    func testUnregisterIgnoresStaleView() async throws {
        let registry = NativeAdAssetRegistry()
        let adView = GoogleMobileAds.NativeAdView()
        registry.adView = adView

        let current = UIView()
        let stale = UIView()
        registry.register(current, for: .headline)
        registry.unregister(stale, for: .headline)
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertIdentical(adView.headlineView, current)
    }

    func testStarRatingImageThresholds() throws {
        XCTAssertNotNil(NativeAdStarRatingView.image(for: NSDecimalNumber(value: 5.0)))
        XCTAssertNotNil(NativeAdStarRatingView.image(for: NSDecimalNumber(value: 4.5)))
        XCTAssertNotNil(NativeAdStarRatingView.image(for: NSDecimalNumber(value: 4.0)))
        XCTAssertNotNil(NativeAdStarRatingView.image(for: NSDecimalNumber(value: 3.5)))
        XCTAssertNil(NativeAdStarRatingView.image(for: NSDecimalNumber(value: 3.4)))
        XCTAssertNil(NativeAdStarRatingView.image(for: nil))
    }
}
