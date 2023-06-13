//
//  InterstitialAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import GoogleMobileAds
import SwiftUI

public class InterstitialAdCoordinator: NSObject, GADFullScreenContentDelegate {
    private var appOpenAd: GADAppOpenAd?
    private var interstitial: GADInterstitialAd?
    private let appOpenadUnitID: String
    private let adUnitID: String
    
    public init(appOpenadUnitID: String = "ca-app-pub-3940256099942544/5662855259", adUnitID: String = "ca-app-pub-3940256099942544/4411468910") {
        self.adUnitID = adUnitID
        self.appOpenadUnitID = appOpenadUnitID
    }
    
    public func loadAd() {
        clean()
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }
    
    public func showAd(from viewController: UIViewController) {
        guard let interstitial = interstitial else {
            return print("Ad wasn't ready")
        }
        
        interstitial.present(fromRootViewController: viewController)
    }
    
    // MARK: - Async/await
    public func loadInterstitialAd() async throws -> GADInterstitialAd {
        clean()
        
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
    
    public func loadAppOpenAd() async throws -> GADAppOpenAd {
        clean()
        
        return try await withCheckedThrowingContinuation { continuation in
            GADAppOpenAd.load(withAdUnitID: appOpenadUnitID, request: GADRequest()) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
    }
    
    private func clean() {
        interstitial = nil
        appOpenAd = nil
    }
    
    // MARK: - GADFullScreenContentDelegate methods
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        clean()
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
