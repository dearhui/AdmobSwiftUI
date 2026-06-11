//
//  BannerViewStyle.swift
//  AdmobSwiftUI
//
//  Created by minghui on 2023/6/13.
//

import Foundation

/// Banner ad display style
public enum BannerViewStyle: Equatable, Sendable {
    /// Anchored adaptive banner - fixed at top or bottom of screen.
    /// Uses the large anchored adaptive size (50-150pt tall, supports video demand).
    case anchored
    /// Inline adaptive banner - embedded within scrollable content.
    /// Height is unknown until the ad loads; observe ``BannerAdEvent/didReceive(adSize:)``.
    case inline
    /// Collapsible banner - an anchored adaptive banner that initially shows a
    /// larger overlay and collapses to the regular anchored size.
    ///
    /// Collapsible banners are only supported for anchored adaptive banners,
    /// which is why this is a separate style rather than an option on `.inline`.
    ///
    /// - Important: Google has strict policies on collapsible banners (display
    ///   frequency, accidental-click prevention, close button behavior, etc.).
    ///   This package only provides the capability; policy compliance is the
    ///   responsibility of the integrating app. See:
    ///   https://support.google.com/admob/answer/14076373
    case collapsible(placement: CollapsiblePlacement)

    /// Where the collapsible banner is anchored on screen. The expanded overlay
    /// grows from this edge, so it must match the banner's actual position.
    public enum CollapsiblePlacement: String, Equatable, Sendable {
        /// Banner anchored at the top of the screen; overlay expands downward.
        case top
        /// Banner anchored at the bottom of the screen; overlay expands upward.
        case bottom
    }
}
