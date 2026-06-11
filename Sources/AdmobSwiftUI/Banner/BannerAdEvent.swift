//
//  BannerAdEvent.swift
//  AdmobSwiftUI
//

import Foundation
import CoreGraphics

/// Lifecycle events emitted by ``BannerView`` via its `onAdEvent` closure.
///
/// All events are delivered on the main actor.
public enum BannerAdEvent {
    /// An ad was loaded. `adSize` is the actual rendered size — for inline
    /// adaptive banners this is the only way to learn the final height.
    case didReceive(adSize: CGSize)
    /// The ad request failed.
    case didFailToReceive(error: any Error)
    /// An impression was recorded for the ad.
    case didRecordImpression
    /// A click was recorded for the ad.
    case didRecordClick
    /// The ad is about to present a full screen view (e.g. after a tap).
    case willPresentScreen
    /// The full screen view is about to be dismissed.
    case willDismissScreen
    /// The full screen view has been dismissed.
    case didDismissScreen
}
