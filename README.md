# AdmobSwiftUI

A Swift package that integrates Google AdMob into SwiftUI applications, with first-class support for Banner, Interstitial, App Open, Rewarded, Rewarded Interstitial, and Native ads — plus built-in UMP consent management (GDPR) and ATT integration.

## ✨ What's New in 3.0

- 🧵 **Swift 6 language mode** — fully concurrency-checked, all coordinators are `@MainActor`
- 🔁 **Unified async/await coordinator API** — `load()` / `present(from:)` / `loadAndPresent(from:)` with observable `adState`
- 🛡️ **UMP consent management** — `initialize()` runs the GDPR consent flow before starting the SDK; ATT helper included
- 🎨 **Pure SwiftUI native ad templates** — XIBs are gone; build fully custom layouts with `AdmobNativeAdContainer`
- 📐 **Self-sizing banners** — no more manual `.frame(height:)`; large anchored adaptive sizes with video demand
- 📂 **Collapsible banners** and banner lifecycle events
- ⬆️ **Google Mobile Ads SDK 13.5+, iOS 15+**

Upgrading from 2.x or 1.x? See the [Migration Guide](MIGRATION.md). Full changes in the [CHANGELOG](CHANGELOG.md).

## Requirements

- iOS 15.0+
- Xcode 16.0+
- Google Mobile Ads SDK 13.5+ (resolved automatically)
- UserMessagingPlatform 3.0+ (resolved automatically)

## Installation

Add the package with Swift Package Manager:

```
https://github.com/dearhui/AdmobSwiftUI.git
```

```swift
.package(url: "https://github.com/dearhui/AdmobSwiftUI.git", from: "3.0.0")
```

## Setup

### 1. Info.plist

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

Optionally delay app measurement until consent is gathered (recommended with UMP):

```xml
<key>GADDelayAppMeasurementInit</key>
<true/>
```

### 2. Build Settings

Add the `-ObjC` flag to "Other Linker Flags".

### 3. Initialize

`initialize()` is async: with the default `.gatherFirst` mode it runs the full UMP consent flow first, and only starts the Mobile Ads SDK once ads can be requested.

```swift
import SwiftUI
import AdmobSwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let config = AdmobSwiftUI.Configuration(
                        enableDebugMode: true   // test ads on simulator/devices
                    )
                    await AdmobSwiftUI.initialize(with: config)
                    // Google recommends requesting ATT after the UMP flow
                    await ConsentManager.shared.requestTrackingAuthorization()
                }
        }
    }
}
```

Prefer to drive consent yourself? Pass `consentMode: .manual` and the SDK starts immediately, exactly like v2.

## Consent Management (UMP + ATT)

```swift
// Run the consent flow manually (no-op if the user already chose)
try await ConsentManager.shared.gatherConsent()

// Required privacy options entry point (e.g. a button in Settings)
if ConsentManager.shared.isPrivacyOptionsRequired {
    try await ConsentManager.shared.presentPrivacyOptionsForm()
}

// Observe status in SwiftUI
@ObservedObject var consent = ConsentManager.shared
// consent.consentStatus: .unknown / .required / .notRequired / .obtained
// consent.canRequestAds
```

Test GDPR behavior from anywhere by simulating an EEA device:

```swift
try await ConsentManager.shared.gatherConsent(
    debugSettings: ConsentDebugSettings(geography: .eea)
)
```

## Ad Unit IDs

`AdmobSwiftUI.AdUnitIDs` switches between Google's test IDs (Debug builds) and your production IDs (Release builds) automatically. Every coordinator and view defaults to it:

```swift
let bannerID = AdmobSwiftUI.AdUnitIDs.banner
AdmobSwiftUI.AdUnitIDs.printCurrentConfiguration()
```

## Banner Ads

Banners size themselves — don't add an external `.frame(height:)`:

```swift
// Anchored adaptive banner (50–150pt tall depending on width, video-capable)
BannerView()

// Inline adaptive banner for scrollable content
BannerView(style: .inline)

// Collapsible banner (mind Google's display policies)
BannerView(style: .collapsible(placement: .bottom))

// Lifecycle events
BannerView { event in
    switch event {
    case .didReceive(let adSize): print("Loaded: \(adSize)")
    case .didFailToReceive(let error): print("Failed: \(error)")
    case .didRecordClick: print("Clicked")
    default: break
    }
}
```

## Interstitial Ads

All fullscreen coordinators share the same shape: `adState` / `isReady` / `load()` / `present(from:)` / `loadAndPresent(from:)`. Include an `AdViewControllerRepresentable` in the hierarchy to obtain a presenting view controller.

```swift
struct ContentView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    @StateObject private var interstitialCoordinator = InterstitialAdCoordinator()

    var body: some View {
        Button("Show Interstitial") {
            Task {
                try? await interstitialCoordinator.loadAndPresent(
                    from: adViewControllerRepresentable.viewController
                )
            }
        }
        .background {
            adViewControllerRepresentable.frame(width: .zero, height: .zero)
        }
    }
}
```

## App Open Ads

Enable `autoReloadsOnForeground` and call `presentIfAvailable()` — expiration (4 hours, per Google policy), reloading after dismissal, and foreground refills are handled for you:

```swift
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appOpenCoordinator = AppOpenAdCoordinator()

    var body: some View {
        ContentView()
            .onAppear { appOpenCoordinator.autoReloadsOnForeground = true }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    appOpenCoordinator.presentIfAvailable()
                }
            }
    }
}
```

## Rewarded Ads

`present(from:)` suspends until the user earns the reward and returns it. Dismissing early throws `AdmobSwiftUIError.rewardNotEarned`:

```swift
@StateObject private var rewardCoordinator = RewardedAdCoordinator()

Button("Watch ad to earn coins") {
    Task {
        do {
            let reward = try await rewardCoordinator.loadAndPresent(
                from: adViewControllerRepresentable.viewController
            )
            grantCoins(reward.amount)   // reward.type from your ad unit config
        } catch {
            print("No reward: \(error)")
        }
    }
}
```

Rewarded interstitials use the same coordinator: `try await rewardCoordinator.load(.rewardedInterstitial)`.

## Native Ads

### Built-in templates

Templates are pure SwiftUI and self-sizing. Nothing is rendered until an ad is loaded:

```swift
struct ContentView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()

    var body: some View {
        NativeAdView(nativeViewModel: nativeViewModel, style: .card)
            .task { try? await nativeViewModel.load() }
    }
}
```

Styles: `.basic` (full layout with media), `.card` (media-led card), `.banner` (compact text row), `.largeBanner` (media left, text right).

> One ad, one view: attaching the same `NativeAd` object to multiple views at once routes media and clicks only to the last one (SDK behavior).

### Custom layouts

Build any layout with `AdmobNativeAdContainer`. The components vended by `NativeAdAssets` are pre-bound to the SDK's asset views, so impressions and clicks are attributed correctly:

```swift
if let ad = nativeViewModel.nativeAd {
    AdmobNativeAdContainer(ad: ad) { assets in
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                assets.icon?.frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading) {
                    assets.headline.font(.headline)
                    assets.starRating?.frame(height: 12)
                }
                Spacer()
                AdBadge()
            }
            assets.body?.font(.subheadline).foregroundStyle(.secondary)
            assets.media.aspectRatio(assets.mediaAspectRatio, contentMode: .fit)
            assets.callToAction?
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.blue, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
}
```

Notes:

- `assets.callToAction` is **not a `Button`** — the SDK owns the tap; just style it like a button.
- Rendering raw data (`assets.ad.headline`, …) with your own views? Tag them with `.nativeAdAsset(.headline)` so clicks are attributed.
- `assets.media` is a real `GADMediaView` — required for video ads.

## Error Handling

All thrown errors are `AdmobSwiftUIError`:

```swift
do {
    try await interstitialCoordinator.loadAndPresent(from: vc)
} catch AdmobSwiftUIError.adLoadFailed(let underlying) {
    print("Load failed: \(underlying)")
} catch AdmobSwiftUIError.adNotLoaded {
    print("Present called before load")
} catch {
    print(error)
}
```

Cases: `adNotLoaded`, `adLoadFailed`, `presentationFailed`, `sdkNotInitialized`, `adExpired`, `invalidConfiguration`, `rewardNotEarned`, `consentGatheringFailed`.

## Logging

```swift
AdmobSwiftUI.logLevel = .debug   // .none / .error / .warning / .info / .debug
```

Defaults to `.debug` in Debug builds and `.error` in Release builds.

## Demo

Open `Demo/AdmobSwitUIDemo.xcodeproj` for a working example of every ad format, the consent flow, and custom native layouts.

## License

AdmobSwiftUI is released under the MIT license. See [LICENSE](LICENSE) for details.
