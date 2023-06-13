# AdmobSwiftUI

AdmobSwiftUI is a Swift package that integrates Admob ads into SwiftUI. This package implements several ways to use Admob in SwiftUI:

- Banner
- Interstitial
- App Open
- Reward
- Reward Interstitial
- Native

## Requirements

- iOS 14.0+
- Google Mobile Ads SDK 10.6.0+

## Installation

You can install AdmobSwiftUI using Swift Package Manager by adding the following URL to your project:

```
https://github.com/dearhui/AdmobSwiftUI.git
```
Before building the project, make sure you've added the -ObjC flag to the "Other Linker Flags" in the "Build Settings".

## Configuration
To use AdmobSwiftUI, you need to add some key values to your Info.plist as required by the Google Mobile Ads SDK. Please refer to the SDK documentation for more details.

Additionally, you need to start the Google Mobile Ads SDK at the start of your app. Add the following code to your @main struct:

```swift
@main
struct AdmobSwitUIDemoApp: App {
    
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Usage

First, you need to import AdmobSwiftUI in your SwiftUI file and initialize all the ad components you need.

```swift
import SwiftUI
import AdmobSwiftUI

struct ContentView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let adCoordinator = InterstitialAdCoordinator()
    private let rewardCoordinator = RewardedAdCoordinator()
```

Then, you can include Banner ads in your view, or show Interstitial or Reward ads when the user performs a certain action.

```swift
    var body: some View {
        ScrollView {
            VStack (spacing: 20) {
            
                Button("Show App Open") {
                    Task {
                        do {
                            let ad = try await adCoordinator.loadAppOpenAd()
                            ad.present(fromRootViewController: adViewControllerRepresentable.viewController)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                Button("Show reward InterstitialAd") {
                    Task {
                        do {
                            let reward = try await rewardCoordinator.loadInterstitialAd()
                            reward.present(fromRootViewController: adViewControllerRepresentable.viewController) {
                                print("Reward amount: \(reward.adReward.amount)")
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                BannerView()
                    .frame(height: 50)
                
                NativeAdView(nativeViewModel: nativeViewModel)
                    .frame(height: 300) // 250 ~ 300
                    .onAppear {
                        nativeViewModel.refreshAd()
                    }
            }
        }
        .padding()
        .background {
            // Add the adViewControllerRepresentable to the background so it
            // doesn't influence the placement of other views in the view hierarchy.
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}
```

## Note

This package uses Google AdMob, make sure your project has imported and configured the Google Mobile Ads SDK properly.

## Contribution

Any form of contribution is welcome, including feature requests, bug reports, or pull requests.

## License

AdmobSwiftUI is released under the MIT license. See [LICENSE](LICENSE) for details.
