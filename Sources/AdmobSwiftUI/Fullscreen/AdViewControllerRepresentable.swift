//
//  File.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

/// Bridges a `UIViewController` into the SwiftUI view hierarchy so full-screen
/// ad coordinators have something to present from.
///
/// Place it in a `.background` with a zero frame and pass its ``viewController``
/// to the coordinator's `present(from:)`.
public struct AdViewControllerRepresentable: UIViewControllerRepresentable {
    /// The hosted view controller; pass it to a coordinator's `present(from:)`.
    public var viewController = UIViewController()

    /// Creates the representable with a fresh hosted view controller.
    public init() {

    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        return viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

/*
 private let adViewControllerRepresentable = AdViewControllerRepresentable()
 
 .background {
     // Add the adViewControllerRepresentable to the background so it
     // doesn't influence the placement of other views in the view hierarchy.
     adViewControllerRepresentable
         .frame(width: .zero, height: .zero)
 }
 */
