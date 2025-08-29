//
//  RewardedAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

public class RewardedAdCoordinator: NSObject, GoogleMobileAds.FullScreenContentDelegate {
    private var rewardedInterstitialAd: GoogleMobileAds.RewardedInterstitialAd?
    private var rewardedAd: GoogleMobileAds.RewardedAd?
    private let adUnitID: String
    private let InterstitialID: String
    
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.rewarded, InterstitialID: String = AdmobSwiftUI.AdUnitIDs.rewardedInterstitial) {
        self.adUnitID = adUnitID
        self.InterstitialID = InterstitialID
    }
    
    public func loadAd() {
        clean()
        GoogleMobileAds.RewardedAd.load(with: adUnitID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
        })
    }
    
    // MARK: - async/await
    
    public func loadInterstitialAd() async throws -> GoogleMobileAds.RewardedInterstitialAd {
        clean()
        return try await withCheckedThrowingContinuation { continuation in
            GoogleMobileAds.RewardedInterstitialAd.load(with: InterstitialID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            })
        }
    }

    public func loadRewardedAd() async throws -> GoogleMobileAds.RewardedAd {
        clean()
        return try await withCheckedThrowingContinuation { continuation in
            GoogleMobileAds.RewardedAd.load(with: adUnitID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
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
        self.rewardedInterstitialAd = nil
        self.rewardedAd = nil
    }
    
    public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        clean()
    }
    
    public func showAd(from viewController: UIViewController, userDidEarnRewardHandler completion: @escaping (Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            return print("Ad wasn't ready")
        }
        
        rewardedAd.present(from: viewController, userDidEarnRewardHandler: {
            let reward = rewardedAd.adReward
            print("Reward amount: \(reward.amount)")
            completion(reward.amount.intValue)
        })
    }
}
