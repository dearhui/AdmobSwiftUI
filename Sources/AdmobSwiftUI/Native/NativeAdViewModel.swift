//
//  SwiftUIView.swift
//  
//
//  Created by minghui on 2023/6/14.
//

import SwiftUI
import GoogleMobileAds

public class NativeAdViewModel: NSObject, ObservableObject, GoogleMobileAds.NativeAdLoaderDelegate {
    @Published public var nativeAd: GoogleMobileAds.NativeAd?
    @Published public var isLoading: Bool = false
    private var adLoader: GoogleMobileAds.AdLoader!
    private var adUnitID: String
    private var lastRequestTime: Date?
    public var requestInterval: Int
    private static var cachedAds: [String: GoogleMobileAds.NativeAd] = [:]
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
        
        let adViewOptions = GoogleMobileAds.NativeAdViewAdOptions()
        adViewOptions.preferredAdChoicesPosition = .topRightCorner
        adLoader = GoogleMobileAds.AdLoader(adUnitID: adUnitID, rootViewController: nil, adTypes: [.native], options: [adViewOptions])
        adLoader.delegate = self
        adLoader.load(GoogleMobileAds.Request())
    }
    
    public func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didReceive nativeAd: GoogleMobileAds.NativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
        self.isLoading = false
        NativeAdViewModel.cachedAds[adUnitID] = nativeAd
        nativeAd.mediaContent.videoController.delegate = self
    }
    
    public func adLoader(_ adLoader: GoogleMobileAds.AdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        self.isLoading = false
    }
}

extension NativeAdViewModel: GoogleMobileAds.VideoControllerDelegate {
    // GADVideoControllerDelegate methods
    public func videoControllerDidPlayVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // begins playing the ad.
    }
    
    public func videoControllerDidPauseVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // pauses the ad.
    }
    
    public func videoControllerDidEndVideoPlayback(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // stops playing the ad.
    }
    
    public func videoControllerDidMuteVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // mutes the ad.
    }
    
    public func videoControllerDidUnmuteVideo(_ videoController: GoogleMobileAds.VideoController) {
        // Implement this method to receive a notification when the video controller
        // unmutes the ad.
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: GoogleMobileAds.NativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: GoogleMobileAds.NativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdDidRecordImpression(_ nativeAd: GoogleMobileAds.NativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdWillPresentScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdWillDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdDidDismissScreen(_ nativeAd: GoogleMobileAds.NativeAd) {
        print("\(#function) called")
    }
}
