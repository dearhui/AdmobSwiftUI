//
//  File.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

// MARK: - Helper to present Interstitial Ad
public struct AdViewControllerRepresentable: UIViewControllerRepresentable {
    public var viewController = UIViewController()
    
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
