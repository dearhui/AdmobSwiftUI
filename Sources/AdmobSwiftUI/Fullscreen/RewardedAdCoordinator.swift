//
//  RewardedAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

public class RewardedAdCoordinator: NSObject, GADFullScreenContentDelegate {
    private var rewardedInterstitialAd: GADRewardedInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    private let adUnitID: String
    private let InterstitialID: String
    
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.rewarded, InterstitialID: String = AdmobSwiftUI.AdUnitIDs.rewardedInterstitial) {
        self.adUnitID = adUnitID
        self.InterstitialID = InterstitialID
    }
    
    public func loadAd() {
        clean()
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    // MARK: - async/await
    
    public func loadInterstitialAd() async throws -> GADRewardedInterstitialAd {
        clean()
        return try await withCheckedThrowingContinuation { continuation in
            GADRewardedInterstitialAd.load(withAdUnitID: InterstitialID, request: GADRequest()) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
    }

    public func loadRewardedAd() async throws -> GADRewardedAd {
        clean()
        return try await withCheckedThrowingContinuation { continuation in
            GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
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
        self.rewardedInterstitialAd = nil
        self.rewardedAd = nil
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        clean()
    }
    
    public func showAd(from viewController: UIViewController, userDidEarnRewardHandler completion: @escaping (Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            return print("Ad wasn't ready")
        }
        
        rewardedAd.present(fromRootViewController: viewController) {
            let reward = rewardedAd.adReward
            print("Reward amount: \(reward.amount)")
            completion(reward.amount.intValue)
        }
    }
}
