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
    
    var view: GADNativeAdView {
        switch self {
        case .basic:
            return makeNibView(name: "NativeAdView")
        case .card:
            return NativeAdCardView(frame: .zero)
        }
    }
    
    func makeNibView(name: String) -> GADNativeAdView {
        let bundle = Bundle.module
        let nib = UINib(nibName: name, bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! GADNativeAdView
    }
}
