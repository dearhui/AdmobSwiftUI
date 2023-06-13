# AdmobSwiftUI

AdmobSwiftUI is a Swift package that integrates Admob ads into SwiftUI. This package implements several ways to use Admob in SwiftUI:

- Banner
- Interstitial
- Reward
- Reward Interstitial
- Native

## Installation

You can install AdmobSwiftUI using Swift Package Manager by adding the following URL to your project:

```
https://github.com/dearhui/AdmobSwiftUI.git
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
                Button("Show InterstitialAd") {
                    Task {
                        do {
                            let ad = try await adCoordinator.loadAd()
                            ad.present(fromRootViewController: adViewControllerRepresentable.viewController)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                Button("show reward") {
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
