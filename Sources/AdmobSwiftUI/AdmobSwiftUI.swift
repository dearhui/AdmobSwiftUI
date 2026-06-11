import Foundation
import GoogleMobileAds

/// AdmobSwiftUI - A SwiftUI integration package for Google AdMob
/// Supports Banner, Interstitial, App Open, Rewarded, and Native ads
public struct AdmobSwiftUI {
    
    /// Package version
    public static let version = "2.1.0"

    /// Internal constants shared across the package
    enum Constants {
        /// App Open ads expire after 4 hours (Google policy)
        static let appOpenAdExpirationInterval: TimeInterval = 4 * 60 * 60
        /// Maximum number of native ads kept in the in-memory cache
        static let nativeAdCacheMaxSize = 10
    }
    
    /// Configuration for AdMob initialization
    public struct Configuration {
        public let testDeviceIdentifiers: [String]?
        public let maxAdContentRating: GADMaxAdContentRating?
        public let enableDebugMode: Bool
        
        public init(
            testDeviceIdentifiers: [String]? = nil,
            maxAdContentRating: GADMaxAdContentRating? = nil,
            enableDebugMode: Bool = false
        ) {
            self.testDeviceIdentifiers = testDeviceIdentifiers
            self.maxAdContentRating = maxAdContentRating
            self.enableDebugMode = enableDebugMode
        }
    }
    
    /// Initialize AdmobSwiftUI with configuration
    /// - Parameter configuration: AdMob configuration settings
    public static func initialize(with configuration: Configuration = Configuration()) {
        let requestConfiguration = MobileAds.shared.requestConfiguration
        
        // Configure test devices
        if configuration.enableDebugMode {
            requestConfiguration.testDeviceIdentifiers = ["ca-app-pub-3940256099942544~1458002511"]
        } else if let testDevices = configuration.testDeviceIdentifiers {
            requestConfiguration.testDeviceIdentifiers = testDevices
        }
        
        // Configure max ad content rating
        if let maxRating = configuration.maxAdContentRating {
            requestConfiguration.maxAdContentRating = maxRating
        }
        
        MobileAds.shared.start { status in
            log("Google Mobile Ads SDK initialized with status: \(status.adapterStatusesByClassName)", level: .info)
        }
    }
    
    /// Check if Google Mobile Ads SDK is initialized
    public static var isInitialized: Bool {
        return MobileAds.shared.initializationStatus.adapterStatusesByClassName.count > 0
    }
    
    // MARK: - Ad Unit IDs Management
    
    /// 廣告 ID 管理中心
    public struct AdUnitIDs {
        
        // MARK: - Google 測試廣告 ID (開發使用)
        
        /// Banner 廣告測試 ID
        public static let testBanner = "ca-app-pub-3940256099942544/2435281174"
        
        /// 插頁廣告測試 ID
        public static let testInterstitial = "ca-app-pub-3940256099942544/4411468910"
        
        /// 獎勵廣告測試 ID
        public static let testRewarded = "ca-app-pub-3940256099942544/1712485313"
        
        /// 獎勵插頁廣告測試 ID
        public static let testRewardedInterstitial = "ca-app-pub-3940256099942544/6978759866"
        
        /// 原生廣告測試 ID
        public static let testNative = "ca-app-pub-3940256099942544/3986624511"
        
        /// App Open 廣告測試 ID
        public static let testAppOpen = "ca-app-pub-3940256099942544/5575463023"
        
        // MARK: - 生產廣告 ID (發布使用)
        // 請替換為你的實際廣告 ID
        
        /// Banner 廣告生產 ID
        public static let productionBanner = "your-banner-ad-unit-id"
        
        /// 插頁廣告生產 ID
        public static let productionInterstitial = "your-interstitial-ad-unit-id"
        
        /// 獎勵廣告生產 ID
        public static let productionRewarded = "your-rewarded-ad-unit-id"
        
        /// 獎勵插頁廣告生產 ID
        public static let productionRewardedInterstitial = "your-rewarded-interstitial-ad-unit-id"
        
        /// 原生廣告生產 ID
        public static let productionNative = "your-native-ad-unit-id"
        
        /// App Open 廣告生產 ID
        public static let productionAppOpen = "your-app-open-ad-unit-id"
        
        // MARK: - 環境配置
        
        /// 當前是否使用測試廣告 ID
        /// 在發布前請設為 false
        public static let useTestAds: Bool = {
            #if DEBUG
            return true  // Debug 模式自動使用測試廣告
            #else
            return false // Release 模式使用生產廣告
            #endif
        }()
        
        // MARK: - 便利方法
        
        /// 根據當前環境獲取 Banner 廣告 ID
        public static var banner: String {
            return useTestAds ? testBanner : productionBanner
        }
        
        /// 根據當前環境獲取插頁廣告 ID
        public static var interstitial: String {
            return useTestAds ? testInterstitial : productionInterstitial
        }
        
        /// 根據當前環境獲取獎勵廣告 ID
        public static var rewarded: String {
            return useTestAds ? testRewarded : productionRewarded
        }
        
        /// 根據當前環境獲取獎勵插頁廣告 ID
        public static var rewardedInterstitial: String {
            return useTestAds ? testRewardedInterstitial : productionRewardedInterstitial
        }
        
        /// 根據當前環境獲取原生廣告 ID
        public static var native: String {
            return useTestAds ? testNative : productionNative
        }
        
        /// 根據當前環境獲取 App Open 廣告 ID
        public static var appOpen: String {
            return useTestAds ? testAppOpen : productionAppOpen
        }
        
        // MARK: - 調試功能
        
        /// 打印當前使用的廣告 ID 配置
        public static func printCurrentConfiguration() {
            let configuration = """
            === AdmobSwiftUI 廣告 ID 配置 ===
            環境: \(useTestAds ? "🧪 測試環境" : "🚀 生產環境")
            Banner: \(banner)
            Interstitial: \(interstitial)
            Rewarded: \(rewarded)
            Rewarded Interstitial: \(rewardedInterstitial)
            Native: \(native)
            App Open: \(appOpen)
            ================================
            """
            AdmobSwiftUI.log(configuration, level: .info)
        }
        
        /// 檢查廣告 ID 是否為測試 ID
        public static func isTestAdID(_ adUnitID: String) -> Bool {
            return adUnitID.hasPrefix("ca-app-pub-3940256099942544")
        }
        
        /// 驗證生產廣告 ID 是否已設置
        public static func validateProductionAds() -> [String] {
            var missingAds: [String] = []
            
            if productionBanner.hasPrefix("your-") {
                missingAds.append("Banner")
            }
            if productionInterstitial.hasPrefix("your-") {
                missingAds.append("Interstitial")
            }
            if productionRewarded.hasPrefix("your-") {
                missingAds.append("Rewarded")
            }
            if productionRewardedInterstitial.hasPrefix("your-") {
                missingAds.append("Rewarded Interstitial")
            }
            if productionNative.hasPrefix("your-") {
                missingAds.append("Native")
            }
            if productionAppOpen.hasPrefix("your-") {
                missingAds.append("App Open")
            }
            
            return missingAds
        }
    }
    
}

/// Unified error types for AdmobSwiftUI
public enum AdmobSwiftUIError: Error, LocalizedError {
    case adNotLoaded
    case adLoadFailed(Error)
    case presentationFailed(String)
    case sdkNotInitialized
    case adExpired
    case invalidConfiguration(String)
    
    public var errorDescription: String? {
        switch self {
        case .adNotLoaded:
            return "Ad is not loaded yet"
        case .adLoadFailed(let error):
            return "Failed to load ad: \(error.localizedDescription)"
        case .presentationFailed(let reason):
            return "Failed to present ad: \(reason)"
        case .sdkNotInitialized:
            return "Google Mobile Ads SDK is not initialized"
        case .adExpired:
            return "The loaded ad has expired and cannot be shown"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}

/// Logging levels for AdmobSwiftUI
public enum AdmobSwiftUILogLevel: Int {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
}

// MARK: - Logging Helper
extension AdmobSwiftUI {
    private static let logLevelLock = NSLock()
    // Guarded by logLevelLock; accessed via the thread-safe `logLevel` property below.
    nonisolated(unsafe) private static var _logLevel: AdmobSwiftUILogLevel = {
        #if DEBUG
        return .debug
        #else
        return .error
        #endif
    }()

    /// Current log level (default: .error for release, .debug for debug)
    public static var logLevel: AdmobSwiftUILogLevel {
        get {
            logLevelLock.lock()
            defer { logLevelLock.unlock() }
            return _logLevel
        }
        set {
            logLevelLock.lock()
            defer { logLevelLock.unlock() }
            _logLevel = newValue
        }
    }
    
    /// Internal logging method
    internal static func log(_ message: String, level: AdmobSwiftUILogLevel = .info) {
        guard logLevel.rawValue >= level.rawValue else { return }
        print("AdmobSwiftUI [\(level)]: \(message)")
    }
}
