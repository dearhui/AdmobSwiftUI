# AdmobSwiftUI

AdmobSwiftUI is a Swift package that integrates Google AdMob ads into SwiftUI applications. It supports multiple ad formats: Banner, Interstitial, App Open, Rewarded, Rewarded Interstitial, and Native ads.

## Requirements

- iOS 14.0+
- Google Mobile Ads SDK 11.2.0+

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
            BannerView()
                .frame(height: 50)
        }
    }
}
```

### Interstitial & App Open Ads

```swift
struct ContentView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let adCoordinator = InterstitialAdCoordinator()
    
    var body: some View {
        VStack {
            Button("Show Interstitial") {
                Task {
                    do {
                        let ad = try await adCoordinator.loadInterstitialAd()
                        ad.present(fromRootViewController: adViewControllerRepresentable.viewController)
                    } catch {
                        print("Failed to show interstitial: \(error)")
                    }
                }
            }
            
            Button("Show App Open") {
                Task {
                    do {
                        let ad = try await adCoordinator.loadAppOpenAd()
                        ad.present(fromRootViewController: adViewControllerRepresentable.viewController)
                    } catch {
                        print("Failed to show app open: \(error)")
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
                    reward.present(fromRootViewController: adViewControllerRepresentable.viewController) {
                        print("User earned reward: \(reward.adReward.amount)")
                    }
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
            NativeAdView(nativeViewModel: nativeViewModel)
                .frame(height: 300)
                .onAppear {
                    nativeViewModel.refreshAd()
                }
        }
    }
}
```

## Error Handling

AdmobSwiftUI provides unified error handling through `AdmobSwiftUIError`:

```swift
enum AdmobSwiftUIError: Error {
    case adNotLoaded
    case adLoadFailed(Error)
    case presentationFailed(String)
    case sdkNotInitialized
}
```

## Notes

This package uses Google AdMob. Ensure your project is properly configured with:
1. Google Mobile Ads SDK integration
2. Info.plist configurations as per Google's documentation
3. `-ObjC` linker flag in build settings
4. Proper ad unit IDs (replace test IDs in production)

## License

AdmobSwiftUI is released under the MIT license. See [LICENSE](LICENSE) for details.