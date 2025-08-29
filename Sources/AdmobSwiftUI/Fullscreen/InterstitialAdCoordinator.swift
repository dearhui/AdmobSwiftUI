//
//  InterstitialAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import GoogleMobileAds
import SwiftUI

public class InterstitialAdCoordinator: NSObject, GoogleMobileAds.FullScreenContentDelegate {
    private var interstitial: GoogleMobileAds.InterstitialAd?
    private let adUnitID: String
    
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.interstitial) {
        self.adUnitID = adUnitID
        super.init()
    }
    
    public func loadAd() {
        clean()
        GoogleMobileAds.InterstitialAd.load(with: adUnitID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
        })
    }
    
    public func showAd(from viewController: UIViewController) {
        guard let interstitial = interstitial else {
            return print("Ad wasn't ready")
        }
        
        interstitial.present(from: viewController)
    }
    
    // MARK: - Async/await
    public func loadInterstitialAd() async throws -> GoogleMobileAds.InterstitialAd {
        clean()
        
        return try await withCheckedThrowingContinuation { continuation in
            GoogleMobileAds.InterstitialAd.load(with: adUnitID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            })
        }
    }
    
    
    private func clean() {
        interstitial = nil
    }
    
    // MARK: - GADFullScreenContentDelegate methods
    public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        clean()
    }
}

// MARK: - Usage Example
/*
struct SampleView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let interstitialAdCoordinator = InterstitialAdCoordinator()
    
    var body: some View {
        VStack {
            Text("Content View")
            
            Button("Load Interstitial Ad") {
                interstitialAdCoordinator.loadAd()
            }
            
            Button("Show Interstitial Ad") {
                interstitialAdCoordinator.showAd(from: adViewControllerRepresentable.viewController)
            }
        }
        .background {
            // Add the adViewControllerRepresentable to the background so it
            // does not influence the placement of other views in the view hierarchy.
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}

// Async/await usage example
struct AsyncSampleView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let interstitialAdCoordinator = InterstitialAdCoordinator()
    
    var body: some View {
        VStack {
            Button("Load & Show Interstitial Ad") {
                Task {
                    do {
                        let ad = try await interstitialAdCoordinator.loadInterstitialAd()
                        ad.present(fromRootViewController: adViewControllerRepresentable.viewController)
                    } catch {
                        print("Failed to load interstitial ad: \(error)")
                    }
                }
            }
        }
        .background {
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}
*/
