import GoogleMobileAds
import SwiftUI

public struct NativeAdView: UIViewRepresentable {
    public typealias UIViewType = GADNativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle
    
    public init(nativeViewModel: NativeAdViewModel, style: NativeAdViewStyle = .basic) {
        self.nativeViewModel = nativeViewModel
        self.style = style
    }
    
    public func makeUIView(context: Context) -> GADNativeAdView {
        return style.view
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

