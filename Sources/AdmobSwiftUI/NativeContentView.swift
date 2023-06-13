import GoogleMobileAds
import SwiftUI

struct NativeContentView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    let navigationTitle: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NativeAdView(nativeViewModel: nativeViewModel)
                    .frame(height: 300)
                
                Text(
                    nativeViewModel.nativeAd?.mediaContent.hasVideoContent == true
                    ? "Ad contains a video asset." : "Ad does not contain a video."
                )
                .frame(maxWidth: .infinity)
                .foregroundColor(.gray)
                .opacity(nativeViewModel.nativeAd == nil ? 0 : 1)
                
                Button("Refresh Ad") {
                    refreshAd()
                }
                
                Text("SDK Version: \(GADMobileAds.sharedInstance().sdkVersion)")
            }
            .padding()
        }
        .onAppear {
            refreshAd()
        }
        .navigationTitle(navigationTitle)
    }
    
    private func refreshAd() {
        nativeViewModel.refreshAd()
    }
}

struct NativeContentView_Previews: PreviewProvider {
    static var previews: some View {
        NativeContentView(navigationTitle: "Native")
    }
}

public  struct NativeAdView: UIViewRepresentable {
    public typealias UIViewType = GADNativeAdView
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    
    public init(nativeViewModel: NativeAdViewModel) {
        self.nativeViewModel = nativeViewModel
    }
    
    public func makeUIView(context: Context) -> GADNativeAdView {
        let bundle = Bundle.module
        let nib = UINib(nibName: "NativeAdView", bundle: bundle)
        let nativeAdView = nib.instantiate(withOwner: nil, options: nil).first as! GADNativeAdView
        return nativeAdView
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
    
    private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
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

public class NativeAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published var nativeAd: GADNativeAd?
    private var adLoader: GADAdLoader!
    private var adUnitID: String
    
    init(adUnitID: String = "ca-app-pub-3940256099942544/3986624511") {
        self.adUnitID = adUnitID
    }
    
    public func refreshAd() {
        adLoader = GADAdLoader(adUnitID: adUnitID, rootViewController: nil, adTypes: [.native], options: nil)
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
    }
    
    public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: GADNativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
    
    public func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("\(#function) called")
    }
}
