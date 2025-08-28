# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AdmobSwiftUI is a Swift package that integrates Google AdMob ads into SwiftUI applications. It supports multiple ad formats: Banner, Interstitial, App Open, Reward, Reward Interstitial, and Native ads.

## Build Commands

This is an iOS-only Swift package targeting iOS 14.0+. The package currently has build issues on macOS due to LBTATools dependency requiring UIKit.

- **Build for iOS**: Use Xcode or build from iOS device/simulator context
- **Test**: `swift test` (currently fails on macOS, needs iOS context)
- **Demo**: Open and run `Demo/AdmobSwitUIDemo.xcodeproj` in Xcode

## Architecture

### Core Components

- **Banner Ads**: `BannerView.swift` and `BannerViewController.swift` - SwiftUI wrapper for GADBannerView
- **Fullscreen Ads**: Coordinators for interstitial, rewarded, and app open ads in `Fullscreen/` directory
- **Native Ads**: Complete native ad implementation with multiple view styles in `Native/` directory
- **AdViewControllerRepresentable**: Bridge for presenting fullscreen ads from SwiftUI

### Directory Structure

```
Sources/AdmobSwiftUI/
├── AdmobSwiftUI.swift          # Package entry point
├── Banner/                     # Banner ad components
├── Fullscreen/                 # Interstitial, rewarded, app open ads
├── Native/                     # Native ad views and view models
├── Extensions/                 # UIColor extensions
└── Resources/                  # XIBs, assets, localizations
```

### Key Dependencies

- Google Mobile Ads SDK (11.2.0+)
- LBTATools for UI utilities
- iOS 14.0+ requirement

### Ad Implementation Pattern

1. Initialize Google Mobile Ads in App delegate: `GADMobileAds.sharedInstance().start(completionHandler: nil)`
2. Use coordinators for fullscreen ads (async/await pattern)
3. Use SwiftUI views directly for banner and native ads
4. Include `AdViewControllerRepresentable` in view hierarchy for fullscreen ad presentation

### Resource Handling

The package includes unhandled resources that should be declared in Package.swift:
- XIB files for native ad layouts
- Asset catalogs
- Localization files
- Info.plist files

### Configuration Requirements

- Add `-ObjC` flag to "Other Linker Flags" in build settings
- Configure Info.plist with Google Mobile Ads requirements
- Initialize GADMobileAds at app startup