//
//  AdCoordinatorProtocol.swift
//  AdmobSwiftUI
//
//  Created by Claude on 2024/8/29.
//

import UIKit

/// Protocol that defines the common interface for all ad coordinators
public protocol AdCoordinatorProtocol {
    /// Check if an ad is currently available to show
    var isAdAvailable: Bool { get }
    
    /// Load an ad (fire-and-forget)
    func loadAd()
    
    /// Show the loaded ad from the specified view controller
    /// - Parameter viewController: The view controller to present from
    /// - Throws: AdmobSwiftUIError if the ad cannot be shown
    func showAd(from viewController: UIViewController) throws
}

/// Protocol for coordinators that support async ad loading
public protocol AsyncAdCoordinatorProtocol: AdCoordinatorProtocol {
    associatedtype AdType
    
    /// Load an ad asynchronously and return it
    /// - Returns: The loaded ad instance
    /// - Throws: AdmobSwiftUIError if loading fails
    func loadAdAsync() async throws -> AdType
}