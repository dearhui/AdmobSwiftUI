# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AdmobSwiftUI is a Swift package that integrates Google AdMob ads into SwiftUI applications. It supports multiple ad formats: Banner, Interstitial, App Open, Rewarded, Rewarded Interstitial, and Native ads, plus UMP consent management (GDPR) and ATT integration.

**Current Version:** 3.0.0

## Build Commands

This is an iOS-only Swift package targeting iOS 15.0+, compiled in Swift 6 language mode.

> ⚠️ GoogleMobileAds is an iOS-only binary target. `swift build` / `swift test` on macOS DO NOT work. Always verify with xcodebuild + iOS Simulator.

- **Build**: `xcodebuild build -scheme AdmobSwiftUI -destination 'generic/platform=iOS Simulator'`
- **Test**: `xcodebuild test -scheme AdmobSwiftUI -destination 'platform=iOS Simulator,name=iPhone 17'` (replace with any installed simulator name)
- **Demo**: Open and run `Demo/AdmobSwitUIDemo.xcodeproj` in Xcode, or:
  ```bash
  xcodebuild build -project Demo/AdmobSwitUIDemo.xcodeproj -scheme AdmobSwitUIDemo -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

CI (`.github/workflows/ci.yml`) runs package tests and the Demo build on every PR and on pushes to `main` / `release/*`.

> Note: 本機網路若有 DNS 層擋廣告（如 AdGuard/Pi-hole 擋 `googleads.g.doubleclick.net`），模擬器上測試廣告會載不出來（SDK 回報 "Could not retrieve application configuration data"）。實測廣告前先確認該網域可解析。

## Architecture

### Core Components

- **AdmobSwiftUI.swift**: Package entry point — async `initialize(with:consentMode:)` (runs UMP consent flow before starting the SDK), Configuration, AdUnitIDs management, error types, logging
- **Banner Ads**: `BannerView` is a self-sizing SwiftUI view (no external `.frame(height:)` needed) with `.anchored` / `.inline` / `.collapsible` styles and `BannerAdEvent` callbacks
- **Fullscreen Ads**: Coordinators in `Fullscreen/`, unified by the `FullScreenAdCoordinator` protocol (`adState` / `isReady` / `load()` / `present(from:)` / `loadAndPresent(from:)`), all `@MainActor`
  - `InterstitialAdCoordinator` - Interstitial ads
  - `AppOpenAdCoordinator` - App Open ads: 4-hour expiration, `autoReloadsOnForeground`, `presentIfAvailable(from:)`
  - `RewardedAdCoordinator` - Rewarded and Rewarded Interstitial ads; `present(from:)` suspends until the reward is earned and returns `AdReward`
- **Native Ads** (`Native/`): pure SwiftUI — `AdmobNativeAdContainer` hosts a custom layout inside a `GADNativeAdView`; `NativeAdAssets` vends pre-bound, click-attributed components; `NativeAdView` renders the built-in templates (`.basic` / `.card` / `.banner` / `.largeBanner`); `NativeAdViewModel` loads with caching/throttling
- **Consent** (`Consent/`): `ConsentManager` (UMP + ATT) over an internal `ConsentService` protocol (mockable in tests)
- **AdViewControllerRepresentable**: Bridge for presenting fullscreen ads from SwiftUI

### Directory Structure

```
Sources/AdmobSwiftUI/
├── AdmobSwiftUI.swift          # Entry point, async initialize, Configuration, AdUnitIDs, errors
├── Banner/
│   ├── BannerView.swift        # Self-sizing SwiftUI banner (representable + coordinator)
│   ├── BannerViewController.swift
│   ├── BannerViewStyle.swift   # .anchored / .inline / .collapsible(placement:)
│   └── BannerAdEvent.swift
├── Fullscreen/
│   ├── InterstitialAdCoordinator.swift
│   ├── AppOpenAdCoordinator.swift
│   ├── RewardedAdCoordinator.swift
│   └── AdViewControllerRepresentable.swift
├── Native/
│   ├── NativeAdContainer.swift  # AdmobNativeAdContainer + asset registry
│   ├── NativeAdAssets.swift     # Pre-bound components, .nativeAdAsset(_:), AdBadge
│   ├── NativeAdTemplates.swift  # Built-in SwiftUI templates
│   ├── NativeAdView.swift
│   ├── NativeAdViewModel.swift
│   ├── NativeAdViewStyle.swift
│   └── AdCache.swift
├── Consent/
│   ├── ConsentManager.swift     # UMP flow + ATT
│   └── ConsentService.swift     # internal protocol (mockable)
├── Protocols/
│   ├── FullScreenAdCoordinator.swift  # AdState, AdReward, protocol
│   └── AdCoordinatorProtocol.swift    # deprecated v2 protocols
└── Resources/                   # assets, localizations (string catalog)
```

### Key Dependencies

- Google Mobile Ads SDK 13.5+
- UserMessagingPlatform 3.0+ (explicitly pinned — UMP 3.0 renamed the whole Swift API)
- iOS 15.0+ requirement

### Ad Implementation Pattern

1. Initialize in App: `await AdmobSwiftUI.initialize()` (in `.task`), then `await ConsentManager.shared.requestTrackingAuthorization()`
2. Use coordinators for fullscreen ads (async/await; `@StateObject`)
3. Use SwiftUI views directly for banner and native ads (both self-sizing — no external height frames)
4. Include `AdViewControllerRepresentable` in view hierarchy for fullscreen ad presentation

### Versioning / Compatibility

- v2 APIs remain as deprecated shims; removal planned for 4.0. Migration paths (v2→v3, v1.2.3→v3) are documented in MIGRATION.md.
- `release/3.0` is the v3 integration branch; PRs for v3 work target it, not `main`.

### Configuration Requirements

- Add `-ObjC` flag to "Other Linker Flags" in build settings
- Info.plist: `GADApplicationIdentifier`, `NSUserTrackingUsageDescription` (ATT); optionally `GADDelayAppMeasurementInit`
- Initialize at app startup: `await AdmobSwiftUI.initialize()`
