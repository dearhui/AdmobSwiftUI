import GoogleMobileAds
import SwiftUI

public enum NativeAdViewStyle {
    case largeBanner
    case card
    case banner
}

public struct NativeAdView: UIViewRepresentable {
    public typealias UIViewType = GADNativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle
    
    public init(nativeViewModel: NativeAdViewModel, style: NativeAdViewStyle) {
        self.nativeViewModel = nativeViewModel
        self.style = style
    }
    
    public func makeUIView(context: Context) -> GADNativeAdView {
        switch style {
        case .largeBanner:
            let bundle = Bundle.module
            let nib = UINib(nibName: "NativeAdView", bundle: bundle)
            return nib.instantiate(withOwner: nil, options: nil).first as! GADNativeAdView
        case .banner:
            return bannerStyleView()
        case .card:
            return cardStyleView()
        }
    }
    
    func cardStyleView() -> GADNativeAdView {
        let bundle = Bundle.module
        let nib = UINib(nibName: "NativeAdViewCard", bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! GADNativeAdView
    }


    
    public func updateUIView(_ nativeAdView: GADNativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        
        // In order for the SDK to process touch events properly, user interaction should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        // Associate the native ad view with the native ad object. This is required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
}

extension NativeAdView {
    func bannerStyleView() -> GADNativeAdView {
        let nativeAdView = GADNativeAdView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(iconView)
        nativeAdView.iconView = iconView
        
        let headlineView = UILabel()
        headlineView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(headlineView)
        nativeAdView.headlineView = headlineView
        
        let starRatingView = UIImageView()
        starRatingView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(starRatingView)
        nativeAdView.starRatingView = starRatingView
        
        let callToActionView = UIButton(type: .system)
        callToActionView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(callToActionView)
        nativeAdView.callToActionView = callToActionView
        
        // Constraints for subviews
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
            iconView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -8),
            
            headlineView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            
            starRatingView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            starRatingView.topAnchor.constraint(equalTo: headlineView.bottomAnchor, constant: 2),
            starRatingView.widthAnchor.constraint(equalToConstant: 100),
            starRatingView.heightAnchor.constraint(equalToConstant: 17),
            
//            callToActionView.leadingAnchor.constraint(equalTo: starRatingView.trailingAnchor, constant: 8),
            callToActionView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
            callToActionView.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
            callToActionView.widthAnchor.constraint(equalToConstant: 60)
        ])
        
        return nativeAdView
    }
    
    func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        
        let bundle = Bundle.module
        
        if rating >= 5 {
            return UIImage(named: "stars_5", in: bundle, compatibleWith: nil)
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5", in: bundle, compatibleWith: nil)
        } else if rating >= 4 {
            return UIImage(named: "stars_4", in: bundle, compatibleWith: nil)
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5", in: bundle, compatibleWith: nil)
        } else {
            return nil
        }
    }
}
