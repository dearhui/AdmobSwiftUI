//
//  File.swift
//  
//
//  Created by minghui on 2023/6/15.
//

import GoogleMobileAds
import UIKit
import LBTATools

class NativeAdCardView: GADNativeAdView {
    
    let adTag: UILabel = UILabel(text: "AD", font: .systemFont(ofSize: 11, weight: .semibold), textColor: .white)
    let headlineLabel = UILabel(text: "", font: .systemFont(ofSize: 17, weight: .medium), textColor: .label)
    let myMediaView = GADMediaView()
    let callToActionButton = UIButton()
    let iconImageView = UIImageView()
    let bodyLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)
    let storeLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)
    let priceLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)
//    let imageView = UIImageView()
    let starRatingImageView = UIImageView()
    let advertiserLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        self.headlineView = headlineLabel
        self.mediaView = myMediaView
        self.callToActionView = callToActionButton
        self.iconView = iconImageView
        bodyLabel.numberOfLines = 2
        self.bodyView = bodyLabel
        self.storeView = storeLabel
        self.priceView = priceLabel
//        self.imageView = imageView
        self.starRatingView = starRatingImageView
//        self.advertiserView = advertiserLabel
        
        addSubview(adTag)
        adTag.backgroundColor = .orange
        adTag.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: nil)
        
        myMediaView.translatesAutoresizingMaskIntoConstraints = false
        myMediaView.heightAnchor.constraint(equalTo: myMediaView.widthAnchor, multiplier: 9.0/16.0).isActive = true
        
        stack(myMediaView,
              stack(
                hstack(iconImageView.withWidth(40).withHeight(40),
                       stack(headlineLabel, hstack(starRatingImageView.withWidth(100).withHeight(17), UIView())),
                       spacing: 8),
                bodyLabel,
                UIView(),
                hstack(UIView(), priceLabel, storeLabel, callToActionButton, spacing: 12)
                , spacing: 8
              ).withMargins(.allSides(10))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

