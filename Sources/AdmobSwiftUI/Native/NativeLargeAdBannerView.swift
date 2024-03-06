//
//  NativeBigAdBannerView.swift
//
//
//  Created by minghui on 2024/3/5.
//

import GoogleMobileAds
import UIKit
import LBTATools

class NativeLargeAdBannerView: GADNativeAdView {
    // require
    let myMediaView = GADMediaView()
    let headlineLabel = UILabel(text: "", font: .systemFont(ofSize: 15, weight: .medium), textColor: .label, numberOfLines: 2)
    let adTag: UILabel = UILabel(text: "AD", font: .systemFont(ofSize: 10, weight: .semibold), textColor: .secondaryLabel, textAlignment: .center)
    
    // for web
    let advertiserLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .secondaryLabel, numberOfLines: 1)
    let bodyLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .secondaryLabel, numberOfLines: 3)
    
    // for app
    let callToActionButton = UIButton(title: "", titleColor: .label, font: .boldSystemFont(ofSize: 14), backgroundColor: .systemBlue, target: nil, action: nil)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        // 設定 media view 的最小尺寸
        myMediaView.translatesAutoresizingMaskIntoConstraints = false
        myMediaView.widthAnchor.constraint(equalTo: myMediaView.heightAnchor, multiplier: 16/9).isActive = true
        myMediaView.contentMode = .scaleAspectFill
        myMediaView.clipsToBounds = true
        self.mediaView = myMediaView

        self.headlineView = headlineLabel
        self.advertiserView = advertiserLabel
        self.bodyView = bodyLabel
        
        callToActionButton.isUserInteractionEnabled = false
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.clipsToBounds = true
        self.callToActionView = callToActionButton
        
        let leftStack = stack(headlineLabel, advertiserLabel, bodyLabel, callToActionButton).withMargins(.init(top: 8, left: 0, bottom: 8, right: 8))

        hstack(myMediaView,leftStack, spacing: 8)
        
        // AD Tag Label
        addSubview(adTag)
        adTag.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adTag.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            adTag.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            adTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 25),
            adTag.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        adTag.backgroundColor = .systemFill
        adTag.layer.cornerRadius = 4
        adTag.clipsToBounds = true
        adTag.text = NSLocalizedString("AD", bundle: .module, comment: "Ad tag label")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
