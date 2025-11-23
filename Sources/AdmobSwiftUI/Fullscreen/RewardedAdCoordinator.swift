//
//  RewardedAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

public class RewardedAdCoordinator: NSObject, FullScreenContentDelegate {
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    private var rewardedAd: RewardedAd?
    private let adUnitID: String
    private let InterstitialID: String
    
    public init(adUnitID: String = "ca-app-pub-3940256099942544/1712485313", InterstitialID: String = "ca-app-pub-3940256099942544/6978759866") {
        self.adUnitID = adUnitID
        self.InterstitialID = InterstitialID
    }
    
    public func loadAd() {
        clean()
        RewardedAd.load(with: adUnitID, request: Request()) { ad, error in
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    // MARK: - async/await
    
    public func loadInterstitialAd() async throws -> RewardedInterstitialAd {
        clean()
        return try await withCheckedThrowingContinuation { continuation in
            RewardedInterstitialAd.load(with: InterstitialID, request: Request()) { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            }
        }
    }

    public func loadRewardedAd() async throws -> RewardedAd {
        clean()
        return try await withCheckedThrowingContinuation { continuation in
            RewardedAd.load(with: adUnitID, request: Request()) { ad, error in
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
    
    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        clean()
    }
    
    public func showAd(from viewController: UIViewController, userDidEarnRewardHandler completion: @escaping (Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            return print("Ad wasn't ready")
        }
        
        rewardedAd.present(from: viewController) {
            let reward = rewardedAd.adReward
            print("Reward amount: \(reward.amount)")
            completion(reward.amount.intValue)
        }
    }
}
