//
//  InterstitialAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import GoogleMobileAds
import SwiftUI

public class InterstitialAdCoordinator: NSObject, GADFullScreenContentDelegate {
    private var interstitial: GADInterstitialAd?
    private let adUnitID: String
    
    public init(adUnitID: String = "ca-app-pub-3940256099942544/4411468910") {
        self.adUnitID = adUnitID
    }
    
    public func loadAd() {
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }
    
    public func loadAd() async throws -> GADInterstitialAd {
        return try await withCheckedThrowingContinuation { continuation in
            GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
    }
    
    public func showAd(from viewController: UIViewController) {
        guard let interstitial = interstitial else {
            return print("Ad wasn't ready")
        }
        
        interstitial.present(fromRootViewController: viewController)
    }
    
    // MARK: - GADFullScreenContentDelegate methods
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitial = nil
    }
}

// Use
/*
struct SampleView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let adCoordinator = InterstitialAdCoordinator()
    
    var body: some View {
        Text("Hello, World!")
            .background {
                // Add the adViewControllerRepresentable to the background so it
                // does not influence the placement of other views in the view hierarchy.
                adViewControllerRepresentable
                    .frame(width: .zero, height: .zero)
            }
        
        Button("Load an ad") {
            adCoordinator.loadAd()
        }
        
        Button("Watch an ad") {
            adCoordinator.showAd(from: adViewControllerRepresentable.viewController)
        }
    }
}
*/
