# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AdmobSwiftUI is a Swift package that integrates Google AdMob ads into SwiftUI applications. It supports multiple ad formats: Banner, Interstitial, App Open, Rewarded, Rewarded Interstitial, and Native ads.

**Current Version:** 2.0.0

## Build Commands

This is an iOS-only Swift package targeting iOS 14.0+.

- **Build for iOS**: Use Xcode or build from iOS device/simulator context
- **Test**: `swift test` (currently fails on macOS, needs iOS context)
- **Demo**: Open and run `Demo/AdmobSwitUIDemo.xcodeproj` in Xcode

## Architecture

### Core Components

- **AdmobSwiftUI.swift**: Package entry point with configuration, ad unit ID management, error types, and logging
- **Banner Ads**: `BannerView.swift`, `BannerViewController.swift`, `BannerViewStyle.swift` - SwiftUI wrapper for adaptive banners
- **Fullscreen Ads**: Separate coordinators for each ad type in `Fullscreen/` directory
  - `InterstitialAdCoordinator.swift` - Interstitial ads
  - `AppOpenAdCoordinator.swift` - App Open ads with 4-hour expiration
  - `RewardedAdCoordinator.swift` - Rewarded and Rewarded Interstitial ads
- **Native Ads**: Complete native ad implementation with multiple view styles in `Native/` directory
- **AdViewControllerRepresentable**: Bridge for presenting fullscreen ads from SwiftUI

### Directory Structure

```
Sources/AdmobSwiftUI/
├── AdmobSwiftUI.swift          # Package entry point, Configuration, AdUnitIDs, Error types
├── Banner/
│   ├── BannerView.swift        # SwiftUI banner view
│   ├── BannerViewController.swift
│   └── BannerViewStyle.swift   # .anchored / .inline styles
├── Fullscreen/
│   ├── InterstitialAdCoordinator.swift
│   ├── AppOpenAdCoordinator.swift
│   ├── RewardedAdCoordinator.swift
│   └── AdViewControllerRepresentable.swift
├── Native/
│   ├── NativeAdView.swift
│   ├── NativeAdViewModel.swift  # Thread-safe caching
│   ├── NativeAdViewStyle.swift
│   └── ... (XIB-based views)
├── Extensions/
│   └── UIColor+Hex.swift
└── Resources/
    └── ... (XIBs, assets, localizations)
```

### Key Dependencies

- Google Mobile Ads SDK 12.9.0+
- iOS 14.0+ requirement

### Ad Implementation Pattern

1. Initialize AdmobSwiftUI in App: `AdmobSwiftUI.initialize()`
2. Use coordinators for fullscreen ads (async/await pattern)
3. Use SwiftUI views directly for banner and native ads
4. Include `AdViewControllerRepresentable` in view hierarchy for fullscreen ad presentation

### Key Features (v2.0.0)

- **AdUnitIDs Management**: Automatic test/production switching based on build configuration
- **Configuration System**: Centralized SDK configuration
- **Error Handling**: Unified `AdmobSwiftUIError` type
- **Logging**: Built-in logging with configurable levels
- **Banner Styles**: `.anchored` (default) and `.inline` for scrollable content
- **Thread-safe Caching**: Native ad cache with size management

### Configuration Requirements

- Add `-ObjC` flag to "Other Linker Flags" in build settings
- Configure Info.plist with `GADApplicationIdentifier`
- Initialize AdmobSwiftUI at app startup: `AdmobSwiftUI.initialize()`
