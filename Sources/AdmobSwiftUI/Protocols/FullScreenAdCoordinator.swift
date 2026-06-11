//
//  FullScreenAdCoordinator.swift
//  AdmobSwiftUI
//
//  Created by Claude on 2026/6/11.
//

import SwiftUI
import UIKit

/// Lifecycle state of a full-screen ad.
public enum AdState: Sendable, Equatable {
    /// No ad is loaded.
    case idle
    /// An ad request is in flight.
    case loading
    /// An ad is loaded and ready to present.
    case ready
    /// The ad is currently on screen.
    case presenting
}

/// Reward earned from a rewarded ad.
public struct AdReward: Sendable, Equatable {
    /// Reward amount, as configured for the ad unit.
    public let amount: Int
    /// Reward type (e.g. "coins"), as configured for the ad unit.
    public let type: String

    /// Creates a reward value.
    public init(amount: Int, type: String) {
        self.amount = amount
        self.type = type
    }
}

/// Unified async/await interface shared by full-screen ad coordinators.
///
/// `InterstitialAdCoordinator` and `AppOpenAdCoordinator` conform directly.
/// `RewardedAdCoordinator` follows the same shape but its `present(from:)`
/// suspends until the user earns the reward and returns an ``AdReward``.
@MainActor
public protocol FullScreenAdCoordinator: AnyObject, ObservableObject {
    /// Current lifecycle state of the ad.
    var adState: AdState { get }

    /// Whether an ad is loaded and can be presented right now.
    var isReady: Bool { get }

    /// Load an ad, replacing any previously loaded one.
    /// - Throws: ``AdmobSwiftUIError/adLoadFailed(_:)`` if the request fails.
    func load() async throws

    /// Present the loaded ad.
    /// - Throws: ``AdmobSwiftUIError/adNotLoaded`` if no ad is ready.
    func present(from viewController: UIViewController) throws

    /// Load an ad if needed, then present it.
    func loadAndPresent(from viewController: UIViewController) async throws
}

extension FullScreenAdCoordinator {
    public var isReady: Bool { adState == .ready }

    public func loadAndPresent(from viewController: UIViewController) async throws {
        if !isReady {
            try await load()
        }
        try present(from: viewController)
    }
}
