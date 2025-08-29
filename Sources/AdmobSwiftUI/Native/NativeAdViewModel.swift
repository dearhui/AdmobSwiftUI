//
//  SwiftUIView.swift
//  
//
//  Created by minghui on 2023/6/14.
//

import SwiftUI
import GoogleMobileAds

public class NativeAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published public var nativeAd: GADNativeAd?
    @Published public var isLoading: Bool = false
    private var adLoader: GADAdLoader!
    private var adUnitID: String
    private var lastRequestTime: Date?
    public var requestInterval: Int
    private static var cachedAds: [String: GADNativeAd] = [:]
    private static var lastRequestTimes: [String: Date] = [:]
    
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.native, requestInterval: Int = 1 * 60) {
        self.adUnitID = adUnitID
        self.requestInterval = requestInterval
        self.nativeAd = NativeAdViewModel.cachedAds[adUnitID]
        self.lastRequestTime = NativeAdViewModel.lastRequestTimes[adUnitID]
    }
    
    public func refreshAd() {
        let now = Date()
        
        if nativeAd != nil, let lastRequest = lastRequestTime, now.timeIntervalSince(lastRequest) < Double(requestInterval) {
            print("The last request was made less than \(requestInterval / 60) minutes ago. New request is canceled.")
            return
        }
        
        guard !isLoading else {
            print("Previous request is still loading, new request is canceled.")
            return
        }
        
        isLoading = true
        lastRequestTime = now
        NativeAdViewModel.lastRequestTimes[adUnitID] = now
        
        let adViewOptions = GADNativeAdViewAdOptions()
        adViewOptions.preferredAdChoicesPosition = .topRightCorner
        adLoader = GADAdLoader(adUnitID: adUnitID, rootViewController: nil, adTypes: [.native], options: [adViewOptions])
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
        self.isLoading = false
        NativeAdViewModel.cachedAds[adUnitID] = nativeAd
        nativeAd.mediaContent.videoController.delegate = self
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        self.isLoading = false
    }
}

extension NativeAdViewModel: GADVideoControllerDelegate {
    // GADVideoControllerDelegate methods
    public func videoControllerDidPlayVideo(_ videoController: GADVideoController) {
        // Implement this method to receive a notification when the video controller
        // begins playing the ad.
    }
    
    public func videoControllerDidPauseVideo(_ videoController: GADVideoController) {
        // Implement this method to receive a notification when the video controller
        // pauses the ad.
    }
    
    public func videoControllerDidEndVideoPlayback(_ videoController: GADVideoController) {
        // Implement this method to receive a notification when the video controller
        // stops playing the ad.
    }
    
    public func videoControllerDidMuteVideo(_ videoController: GADVideoController) {
        // Implement this method to receive a notification when the video controller
        // mutes the ad.
    }
    
    public func videoControllerDidUnmuteVideo(_ videoController: GADVideoController) {
        // Implement this method to receive a notification when the video controller
        // unmutes the ad.
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: GADNativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
}
