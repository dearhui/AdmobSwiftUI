# AdmobSwiftUI

AdmobSwiftUI is a Swift package that integrates Google AdMob ads into SwiftUI applications. It supports multiple ad formats: Banner, Interstitial, App Open, Rewarded, Rewarded Interstitial, and Native ads.

## ✨ Latest Updates (v2.0.0)

- 🚀 **Upgraded to AdMob SDK v12.9.0** - Latest features and improvements
- 🏗️ **Improved Architecture** - Separated App Open ads into dedicated coordinator
- 🔧 **Better API Design** - Cleaner and more intuitive API
- ⚡ **Enhanced Performance** - Optimized ad loading and memory management
- 📱 **Inline Banner Support** - New banner style for scrollable content

## Requirements

- iOS 14.0+
- Xcode 16.0+
- Google Mobile Ads SDK 12.9.0+

## Installation

You can install AdmobSwiftUI using Swift Package Manager by adding the following URL to your project:

```
https://github.com/dearhui/AdmobSwiftUI.git
```

## Configuration

### 1. Info.plist Setup
Add the required keys to your Info.plist as specified in the Google Mobile Ads SDK documentation.

### 2. Initialize AdmobSwiftUI
Initialize AdmobSwiftUI in your App's init method:

```swift
import SwiftUI
import AdmobSwiftUI

@main
struct AdmobSwitUIDemoApp: App {
    
    init() {
        // Basic initialization
        AdmobSwiftUI.initialize()
        
        // Or with custom configuration
        let config = AdmobSwiftUI.Configuration(
            testDeviceIdentifiers: ["your-test-device-id"],
            maxAdContentRating: .general,
            enableDebugMode: true  // Enable for development
        )
        AdmobSwiftUI.initialize(with: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Build Settings
Add the `-ObjC` flag to "Other Linker Flags" in your Build Settings.

## Ad Unit ID Management

AdmobSwiftUI provides a centralized ad unit ID management system that automatically switches between test and production environments:

```swift
import AdmobSwiftUI

// Use centrally managed ad unit IDs
let bannerID = AdmobSwiftUI.AdUnitIDs.banner        // Automatically selects test or production ID
let interstitialID = AdmobSwiftUI.AdUnitIDs.interstitial

// Use test ad unit IDs directly
let testBannerID = AdmobSwiftUI.AdUnitIDs.testBanner

// Check current configuration
AdmobSwiftUI.AdUnitIDs.printCurrentConfiguration()
```

**Automatic Environment Switching:**
- 🧪 **Debug Mode**: Automatically uses test ad unit IDs
- 🚀 **Release Mode**: Automatically uses production ad unit IDs

## Usage Examples

### Banner Ads

```swift
import SwiftUI
import AdmobSwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            // Default anchored banner (fixed at top/bottom)
            BannerView()
                .frame(height: 50)

            // Inline banner (for scrollable content)
            BannerView(style: .inline)
                .frame(height: 50)
        }
    }
}
```

**Banner Styles:**
- `.anchored` (default) - Fixed position banner, ideal for top/bottom of screen
- `.inline` - Adaptive banner for embedding within scrollable content like `ScrollView` or `List`

### Interstitial Ads

```swift
struct ContentView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let interstitialCoordinator = InterstitialAdCoordinator()
    
    var body: some View {
        VStack {
            Button("Show Interstitial") {
                Task {
                    do {
                        let ad = try await interstitialCoordinator.loadInterstitialAd()
                        ad.present(from: adViewControllerRepresentable.viewController)
                    } catch {
                        print("Failed to show interstitial: \(error)")
                    }
                }
            }
        }
        .background {
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}
```

### App Open Ads

> **⚠️ Breaking Change in v2.0.0**: App Open ads now have their own dedicated coordinator for better lifecycle management.

```swift
struct ContentView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let appOpenAdCoordinator = AppOpenAdCoordinator()
    
    var body: some View {
        VStack {
            Button("Show App Open Ad") {
                Task {
                    do {
                        let ad = try await appOpenAdCoordinator.loadAppOpenAd()
                        ad.present(from: adViewControllerRepresentable.viewController)
                    } catch {
                        print("Failed to show app open ad: \(error)")
                    }
                }
            }
        }
        .background {
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
        .onAppear {
            // Preload app open ad for better UX
            appOpenAdCoordinator.loadAd()
        }
    }
}
```

**App Open Ad Features:**
- ⏰ **Smart Expiration**: Automatically expires after 4 hours
- 🔄 **Lifecycle Management**: Proper foreground/background handling  
- 🎯 **State Tracking**: Built-in availability checking

### Rewarded Ads

```swift
struct ContentView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let rewardCoordinator = RewardedAdCoordinator()
    
    var body: some View {
        Button("Show Rewarded Ad") {
            Task {
                do {
                    let reward = try await rewardCoordinator.loadRewardedAd()
                    reward.present(from: adViewControllerRepresentable.viewController, userDidEarnRewardHandler: {
                        print("User earned reward: \(reward.adReward.amount)")
                    })
                } catch {
                    print("Failed to show rewarded ad: \(error)")
                }
            }
        }
        .background {
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}
```

### Native Ads

```swift
struct ContentView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    
    var body: some View {
        VStack {
            // Multiple native ad styles available
            NativeAdView(nativeViewModel: nativeViewModel, style: .card)
                .frame(height: 300)
            
            NativeAdView(nativeViewModel: nativeViewModel, style: .banner)
                .frame(height: 100)
                
            NativeAdView(nativeViewModel: nativeViewModel, style: .largeBanner)
                .frame(height: 200)
        }
        .onAppear {
            nativeViewModel.refreshAd()
        }
    }
}
```

**Native Ad Styles:**
- `.card` - Full-featured card layout with media
- `.banner` - Compact banner style
- `.largeBanner` - Larger banner with more content
- `.basic` - Custom XIB-based layout

## 🔄 Migration Guide (v1.x → v2.0.0)

### SDK Initialization
**Before (v1.x):**
```swift
import GoogleMobileAds

@main
struct MyApp: App {
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}
```

**After (v2.0.0):**
```swift
import AdmobSwiftUI

@main
struct MyApp: App {
    init() {
        AdmobSwiftUI.initialize()
        // Or with configuration
        // AdmobSwiftUI.initialize(with: .init(enableDebugMode: true))
    }
}
```

### App Open Ads
**Before (v1.x):**
```swift
private let adCoordinator = InterstitialAdCoordinator()

// This no longer works
let ad = try await adCoordinator.loadAppOpenAd()
```

**After (v2.0.0):**
```swift
private let appOpenAdCoordinator = AppOpenAdCoordinator()

let ad = try await appOpenAdCoordinator.loadAppOpenAd()
```

### API Method Updates
| v1.x | v2.0.0 |
|------|--------|
| `GADMobileAds.sharedInstance().start()` | `AdmobSwiftUI.initialize()` |
| `present(fromRootViewController:)` | `present(from:)` |
| `GADRequest()` | `GoogleMobileAds.Request()` |
| Hardcoded test ad unit IDs | `AdmobSwiftUI.AdUnitIDs.banner` etc.

## Notes

This package uses Google AdMob SDK v12.9.0. Ensure your project is properly configured with:
1. **Xcode 16.0+** - Required for AdMob SDK v12
2. **Info.plist configurations** - Add `GADApplicationIdentifier`
3. **Build Settings** - Add `-ObjC` linker flag  
4. **Ad Unit IDs** - Replace test IDs with production IDs before release

## License

AdmobSwiftUI is released under the MIT license. See [LICENSE](LICENSE) for details.