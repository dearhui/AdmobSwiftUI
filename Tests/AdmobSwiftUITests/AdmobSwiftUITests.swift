import XCTest
@testable import AdmobSwiftUI

final class AdmobSwiftUITests: XCTestCase {
    
    func testAdmobSwiftUIVersion() throws {
        XCTAssertEqual(AdmobSwiftUI.version, "1.0.0")
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
        let adNotLoadedError = AdmobSwiftUIError.adNotLoaded
        XCTAssertEqual(adNotLoadedError.errorDescription, "Ad is not loaded yet")
        
        let sdkNotInitializedError = AdmobSwiftUIError.sdkNotInitialized
        XCTAssertEqual(sdkNotInitializedError.errorDescription, "Google Mobile Ads SDK is not initialized")
        
        let testError = NSError(domain: "Test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let adLoadFailedError = AdmobSwiftUIError.adLoadFailed(testError)
        XCTAssertEqual(adLoadFailedError.errorDescription, "Failed to load ad: Test error")
        
        let presentationFailedError = AdmobSwiftUIError.presentationFailed("Test reason")
        XCTAssertEqual(presentationFailedError.errorDescription, "Failed to present ad: Test reason")
    }
}

final class InterstitialAdCoordinatorTests: XCTestCase {
    
    var coordinator: InterstitialAdCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = InterstitialAdCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    func testInterstitialAdCoordinatorInitialization() throws {
        XCTAssertNotNil(coordinator)
    }
    
    func testInterstitialAdCoordinatorWithCustomAdUnits() throws {
        let customCoordinator = InterstitialAdCoordinator(
            appOpenadUnitID: "test-app-open-id",
            adUnitID: "test-interstitial-id"
        )
        XCTAssertNotNil(customCoordinator)
    }
}

final class RewardedAdCoordinatorTests: XCTestCase {
    
    var coordinator: RewardedAdCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = RewardedAdCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    func testRewardedAdCoordinatorInitialization() throws {
        XCTAssertNotNil(coordinator)
    }
    
    func testRewardedAdCoordinatorWithCustomAdUnits() throws {
        let customCoordinator = RewardedAdCoordinator(
            adUnitID: "test-rewarded-id",
            InterstitialID: "test-rewarded-interstitial-id"
        )
        XCTAssertNotNil(customCoordinator)
    }
}

final class NativeAdViewModelTests: XCTestCase {
    
    var viewModel: NativeAdViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = NativeAdViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testNativeAdViewModelInitialization() throws {
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.nativeAd)
        XCTAssertEqual(viewModel.requestInterval, 60) // 1 minute default
    }
    
    func testNativeAdViewModelWithCustomInterval() throws {
        let customViewModel = NativeAdViewModel(requestInterval: 300) // 5 minutes
        XCTAssertEqual(customViewModel.requestInterval, 300)
    }
    
    func testNativeAdViewModelWithCustomAdUnit() throws {
        let customViewModel = NativeAdViewModel(adUnitID: "custom-ad-unit-id")
        XCTAssertNotNil(customViewModel)
    }
}
