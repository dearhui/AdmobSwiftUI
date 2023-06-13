//
//  RewardedAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

public class RewardedAdCoordinator: NSObject, GADFullScreenContentDelegate {
    private var rewardedAd: GADRewardedAd?
    private let adUnitID: String
    
    public init(adUnitID: String = "ca-app-pub-3940256099942544/1712485313") {
        self.adUnitID = adUnitID
    }
    
    public func loadAd() {
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { ad, error in
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    public func loadAd() async throws -> GADRewardedAd {
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
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        rewardedAd = nil
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
