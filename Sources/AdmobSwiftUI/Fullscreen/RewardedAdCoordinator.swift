//
//  RewardedAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
@preconcurrency import GoogleMobileAds

@MainActor
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
        Task {
            do {
                let ad = try await GoogleMobileAds.RewardedAd.load(with: adUnitID, request: GoogleMobileAds.Request())
                self.rewardedAd = ad
                ad.fullScreenContentDelegate = self
            } catch {
                AdmobSwiftUI.log("Failed to load rewarded ad: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    // MARK: - async/await
    
    public func loadInterstitialAd() async throws -> GoogleMobileAds.RewardedInterstitialAd {
        clean()
        let ad = try await GoogleMobileAds.RewardedInterstitialAd.load(with: InterstitialID, request: GoogleMobileAds.Request())
        ad.fullScreenContentDelegate = self
        return ad
    }

    public func loadRewardedAd() async throws -> GoogleMobileAds.RewardedAd {
        clean()
        let ad = try await GoogleMobileAds.RewardedAd.load(with: adUnitID, request: GoogleMobileAds.Request())
        ad.fullScreenContentDelegate = self
        return ad
    }
    
    private func clean() {
        rewardedInterstitialAd?.fullScreenContentDelegate = nil
        rewardedAd?.fullScreenContentDelegate = nil
        self.rewardedInterstitialAd = nil
        self.rewardedAd = nil
    }
    
    public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        clean()
    }
    
    public func showAd(from viewController: UIViewController, userDidEarnRewardHandler completion: @escaping (Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            AdmobSwiftUI.log("Rewarded ad wasn't ready", level: .warning)
            return
        }

        rewardedAd.present(from: viewController, userDidEarnRewardHandler: {
            let reward = rewardedAd.adReward
            AdmobSwiftUI.log("Reward amount: \(reward.amount)", level: .debug)
            completion(reward.amount.intValue)
        })
    }
}
