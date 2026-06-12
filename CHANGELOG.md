# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2026-06-12

### Added

- **`BannerViewStyle.inline(maxHeight:)`** caps the height of inline adaptive banners. Without a cap, Google's inline adaptive size may grow up to the device height, which can make embedded ads unexpectedly tall. `nil` (or the existing `.inline` shorthand) keeps the uncapped behaviour. Google requires `maxHeight >= 32` and recommends `>= 50`.

## [3.0.1] - 2026-06-12

### Fixed

- **Native ads no longer stretch to fill a concrete height proposal.** `NativeAdView` / `AdmobNativeAdContainer` adopted the parent's proposed height in `sizeThatFits`, so placing the ad directly in a `VStack` (outside a `List`/`ScrollView`) stretched it over the leftover screen space with the content floating in the middle. The view now always hugs its content height for the proposed width, matching the "automatic height" behaviour documented in MIGRATION.md and making sizing consistent across containers.

## [3.0.0] - 2026-06-11

A major release: Google Mobile Ads SDK 13, Swift 6 language mode, a unified async/await API, UMP consent management, pure-SwiftUI native ads, and self-sizing banners. See [MIGRATION.md](MIGRATION.md) for upgrade paths from 2.x and 1.x.

### Changed (Breaking)

- **Minimum iOS version raised to 15.0**; Google Mobile Ads SDK pinned to 13.5+.
- **`AdmobSwiftUI.initialize(with:consentMode:)` is now async** and runs the UMP consent flow before starting the SDK by default (`.gatherFirst`). Pass `.manual` to opt out. The synchronous `initialize(with:)` is deprecated.
- **Package compiles in Swift 6 language mode**; `InterstitialAdCoordinator`, `AppOpenAdCoordinator`, `RewardedAdCoordinator`, `NativeAdViewModel`, and `ConsentManager` are `@MainActor`.
- **Banner heights are now automatic** — remove external `.frame(height:)`. Anchored banners use the large anchored adaptive size (50–150pt, video-capable) instead of the fixed ~50pt size.
- **`NativeAdView` renders nothing until an ad is loaded** (v2 rendered an empty template skeleton) and sizes itself — remove external `.frame(height:)`.
- **`.basic` native template reimplemented in SwiftUI** (was XIB); layout is equivalent with pixel-level differences.
- `AdmobSwiftUIError` gains `adExpired`, `invalidConfiguration`, `rewardNotEarned`, and `consentGatheringFailed` cases (exhaustive switches must be updated).

### Added

- `FullScreenAdCoordinator` protocol unifying coordinators: `adState` (`@Published`), `isReady`, `load()`, `present(from:)`, `loadAndPresent(from:)`.
- `RewardedAdCoordinator.present(from:)` suspends until the reward is earned and returns an `AdReward(amount:type:)`; early dismissal throws `rewardNotEarned`. `load(_:)` selects `.rewarded` / `.rewardedInterstitial`.
- `AppOpenAdCoordinator.autoReloadsOnForeground` and `presentIfAvailable(from:)` replace hand-written scene-phase reload boilerplate; loaded ads expire after 4 hours per Google policy.
- `ConsentManager` (UMP): `gatherConsent`, `presentPrivacyOptionsForm`, `requestTrackingAuthorization` (ATT), `reset`, `@Published consentStatus`, `canRequestAds`, `isPrivacyOptionsRequired`, plus `ConsentDebugSettings` with geography overrides (`.eea`, `.regulatedUSState`, `.other`).
- `BannerViewStyle.collapsible(placement:)` for collapsible anchored banners.
- `BannerAdEvent` lifecycle events via `BannerView`'s `onAdEvent` closure (load success/failure, impression, click, screen presentation).
- Custom native ad layout API: `AdmobNativeAdContainer`, `NativeAdAssets` (pre-bound, click-attributed components), `.nativeAdAsset(_:)` modifier, and `AdBadge`.
- `NativeAdViewModel.load()` async API with per-ad-unit caching and request throttling.
- DocC documentation for all public APIs; CI on GitHub Actions.

### Deprecated (removal planned for 4.0)

- Synchronous `AdmobSwiftUI.initialize(with:)`.
- Coordinator v2 APIs: `loadAd()`, `showAd(from:)`, `loadInterstitialAd()`, `loadAppOpenAd()`, `loadAdAsync()`, `loadRewardedAd()`, `isAdAvailable`, `RewardedAdCoordinator.init(adUnitID:InterstitialID:)`, `showAd(from:userDidEarnRewardHandler:)`.
- `NativeAdViewModel.refreshAd()`.
- `AdCoordinatorProtocol` / `AsyncAdCoordinatorProtocol` (use `FullScreenAdCoordinator`).

### Removed

- Native ad XIBs and UIKit layout helpers (`NativeAdView.xib`, code-layout views, `UIView`/`UIColor` extensions).

## [2.1.0] - 2026-06-11

- Fixed `BannerView` never loading: the `GADBannerView` was stored on the representable struct and recreated on every render; it now lives on the coordinator.
- Rebuilt test suite (22 tests) and fixed pre-existing technical debt. Non-breaking.

## [2.0.0] - 2025

- Upgraded to Google Mobile Ads SDK 12.9; iOS 14, Xcode 16 required.
- Split App Open ads into a dedicated `AppOpenAdCoordinator`.
- Added `AdmobSwiftUI.initialize()` / `Configuration`, `AdUnitIDs` test/production switching, `AdmobSwiftUIError`, logging, `.inline` banner style, and thread-safe native ad caching.
