//
//  File.swift
//  
//
//  Created by minghui on 2023/6/15.
//

import GoogleMobileAds
import SwiftUI

public enum NativeAdViewStyle {
    case basic
    case card
    case banner
    case largeBanner
    
    @MainActor
    var view: GoogleMobileAds.NativeAdView {
        switch self {
        case .basic:
            return makeNibView(name: "NativeAdView")
        case .card:
            return NativeAdCardView(frame: .zero)
        case .banner:
            return NativeAdBannerView(frame: .zero)
        case .largeBanner:
            return NativeLargeAdBannerView(frame: .zero)
        }
    }
    
    @MainActor
    func makeNibView(name: String) -> GoogleMobileAds.NativeAdView {
        let bundle = Bundle.module
        let nib = UINib(nibName: name, bundle: bundle)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? GoogleMobileAds.NativeAdView else {
            assertionFailure("AdmobSwiftUI: Failed to load \(name).xib as NativeAdView")
            AdmobSwiftUI.log("Failed to load \(name).xib as NativeAdView, falling back to empty view", level: .error)
            return GoogleMobileAds.NativeAdView(frame: .zero)
        }
        return view
    }
}
