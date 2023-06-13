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
    private let bannerView = GADBannerView()
    private let adUnitID: String
    
    public init(adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        self.adUnitID = adUnitID
    }
    
    public func makeUIViewController(context: Context) -> some UIViewController {
        let bannerViewController = BannerViewController()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = bannerViewController
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
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView.load(GADRequest())
    }
    
    public class Coordinator: NSObject, BannerViewControllerWidthDelegate {
        let parent: BannerView
        
        init(_ parent: BannerView) {
            self.parent = parent
        }
        
        // MARK: - BannerViewControllerWidthDelegate methods
        
        func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            // Pass the viewWidth from Coordinator to BannerView.
            parent.viewWidth = width
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("\(#function) called")
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }
        
        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            BannerView()
                .frame(width: geometry.size.width, height: 50)
                .background(Color.red)
        }
    }
}
