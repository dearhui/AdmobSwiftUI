//
//  InterstitialAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import GoogleMobileAds
import SwiftUI

public class InterstitialAdCoordinator: NSObject, FullScreenContentDelegate {
    private var appOpenAd: AppOpenAd?
    private var interstitial: InterstitialAd?
    private let appOpenadUnitID: String
    private let adUnitID: String
    
    public init(appOpenadUnitID: String = "ca-app-pub-3940256099942544/5662855259", adUnitID: String = "ca-app-pub-3940256099942544/4411468910") {
        self.adUnitID = adUnitID
        self.appOpenadUnitID = appOpenadUnitID
    }
    
    public func loadAd() {
        clean()
        InterstitialAd.load(with: adUnitID, request: Request()) { ad, error in
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        }
    }
    
    public func showAd(from viewController: UIViewController) {
        guard let interstitial = interstitial else {
            return print("Ad wasn't ready")
        }
        
        interstitial.present(from: viewController)
    }
    
    // MARK: - Async/await
    public func loadInterstitialAd() async throws -> InterstitialAd {
        clean()
        
        return try await withCheckedThrowingContinuation { continuation in
            InterstitialAd.load(with: adUnitID, request: Request()) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
    }
    
    public func loadAppOpenAd() async throws -> AppOpenAd {
        clean()
        
        return try await withCheckedThrowingContinuation { continuation in
            AppOpenAd.load(with: appOpenadUnitID, request: Request()) { ad, error in
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
    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
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
