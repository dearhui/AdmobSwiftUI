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
        print("size: \(viewWidth)")
        guard viewWidth != .zero else { return }
        
        // Request a banner ad with the updated viewWidth.
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        bannerView.load(GoogleMobileAds.Request())
    }
    
    public class Coordinator: NSObject, BannerViewControllerWidthDelegate, GoogleMobileAds.BannerViewDelegate {
        let parent: BannerView
        
        init(_ parent: BannerView) {
            self.parent = parent
        }
        
        // MARK: - BannerViewControllerWidthDelegate methods
        
        func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            // Pass the viewWidth from Coordinator to BannerView.
            parent.viewWidth = width
        }
        
        public func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            print("\(#function) called")
        }
        
        public func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            print("\(#function) called")
        }
        
        public func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
            print("\(#function) called")
        }
        
        public func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("\(#function) called")
        }
        
        public func bannerViewWillDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("\(#function) called")
        }
        
        public func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("\(#function) called")
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        BannerView()
    }
}
