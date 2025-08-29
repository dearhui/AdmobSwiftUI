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
    
    func makeNibView(name: String) -> GoogleMobileAds.NativeAdView {
        let bundle = Bundle.module
        let nib = UINib(nibName: name, bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! GoogleMobileAds.NativeAdView
    }
}
