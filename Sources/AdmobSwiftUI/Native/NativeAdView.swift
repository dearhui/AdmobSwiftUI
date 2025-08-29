import GoogleMobileAds
import SwiftUI

public struct NativeAdView: UIViewRepresentable {
    public typealias UIViewType = GoogleMobileAds.NativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle
    
    public init(nativeViewModel: NativeAdViewModel, style: NativeAdViewStyle = .basic) {
        self.nativeViewModel = nativeViewModel
        self.style = style
    }
    
    public func makeUIView(context: Context) -> GoogleMobileAds.NativeAdView {
        return style.view
    }
    
    func removeCurrentSizeConstraints(from mediaView: UIView) {
        mediaView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                mediaView.removeConstraint(constraint)
            }
        }
    }
    
    public func updateUIView(_ nativeAdView: GoogleMobileAds.NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
        if let mediaView = nativeAdView.mediaView {
            mediaView.contentMode = .scaleAspectFill
            mediaView.clipsToBounds = true

            let aspectRatio = nativeAd.mediaContent.aspectRatio

            debugPrint("Google aspectRatio: \(aspectRatio), hasVideoContent: \(nativeAd.mediaContent.hasVideoContent)")
            
            if style == .largeBanner {
                removeCurrentSizeConstraints(from: mediaView)
                if aspectRatio > 0 {
                    if aspectRatio > 1 {
                        mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: aspectRatio).isActive = true
                    } else {
                        mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: 1).isActive = true
                    }
                } else {
                    mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: 16/9).isActive = true
                }
            }
        }
        
        // headline require
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // body
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        // icon
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = (nativeAd.icon == nil)
        
        // ratting
        let starRattingImage = imageOfStars(from: nativeAd.starRating)
        (nativeAdView.starRatingView as? UIImageView)?.image = starRattingImage
        nativeAdView.starRatingView?.isHidden = (starRattingImage == nil)
        
        // store
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil
        
        // price
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        // advertiser
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = (nativeAd.advertiser == nil)
        
        // button
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        if style == .largeBanner, let body = nativeAd.body, body.count > 0 {
            nativeAdView.callToActionView?.isHidden = true
        }
        
        // Associate the native ad view with the native ad object. This is required to make the ad clickable.
        // Note: this should always be done after populating the ad views.
        nativeAdView.nativeAd = nativeAd
    }
}

extension NativeAdView {
    
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


struct NativeAdView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一个模拟的 NativeAdViewModel
        let viewModel = NativeAdViewModel()  // 可能需要根据你的实际情况进行修改
        // 假设 NativeAdViewStyle.basic 是一个有效的样式
        ScrollView {
            VStack {
                NativeAdView(nativeViewModel: viewModel, style: .card)
                    .frame(width: .infinity, height: 300)
                    .background(Color.red)
            }
            .padding()
        }
        .background(Color.gray)
    }
}

