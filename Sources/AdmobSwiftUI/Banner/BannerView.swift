//
//  BannerView.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

public struct BannerView: UIViewControllerRepresentable {
    @State private var viewWidth: CGFloat = .zero
    @State private var currentAdSize: AdSize?
    private let bannerView = GoogleMobileAds.BannerView()
    private let adUnitID: String
    
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.banner) {
        self.adUnitID = adUnitID
    }
    
    public func makeUIViewController(context: Context) -> some UIViewController {
        let bannerViewController = BannerViewController()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator
        bannerViewController.view.addSubview(bannerView)
        bannerViewController.delegate = context.coordinator
        
        return bannerViewController
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        AdmobSwiftUI.log("Banner view width updated: \(viewWidth)", level: .debug)
        guard viewWidth != .zero else { return }
        
        // Only reload if size actually changed
        let newAdSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        if currentAdSize == nil || !isAdSizeEqualToSize(size1: currentAdSize!, size2: newAdSize) {
            DispatchQueue.main.async {
                self.currentAdSize = newAdSize
            }
            bannerView.adSize = newAdSize
            bannerView.load(GoogleMobileAds.Request())
        }
    }
    
    public class Coordinator: NSObject, BannerViewControllerWidthDelegate, GoogleMobileAds.BannerViewDelegate {
        let parent: BannerView
        
        init(_ parent: BannerView) {
            self.parent = parent
        }
        
        // MARK: - BannerViewControllerWidthDelegate methods
        
        func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            // Pass the viewWidth from Coordinator to BannerView.
            DispatchQueue.main.async {
                self.parent.viewWidth = width
            }
        }
        
        public func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad received successfully", level: .debug)
        }
        
        public func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            AdmobSwiftUI.log("Banner ad failed to load: \(error.localizedDescription)", level: .error)
        }
        
        public func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad impression recorded", level: .debug)
        }
        
        public func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad will present screen", level: .debug)
        }
        
        public func bannerViewWillDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad will dismiss screen", level: .debug)
        }
        
        public func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            AdmobSwiftUI.log("Banner ad did dismiss screen", level: .debug)
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        BannerView()
    }
}
