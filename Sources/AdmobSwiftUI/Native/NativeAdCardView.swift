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
    let callToActionButton = UIButton(title: "", titleColor: .white, font: .boldSystemFont(ofSize: 18), backgroundColor: UIColor(hex: "#3871E0"), target: nil, action: nil)
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
        
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.clipsToBounds = true
        
        addSubview(adTag)
        adTag.backgroundColor = .orange
        adTag.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: nil)
        
        myMediaView.translatesAutoresizingMaskIntoConstraints = false
        myMediaView.heightAnchor.constraint(equalTo: myMediaView.widthAnchor, multiplier: 9.0/16.0).isActive = true
        
//        iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor, multiplier: 1).isActive = true
        iconImageView.layer.cornerRadius = 4
        iconImageView.clipsToBounds = true
        
        stack(myMediaView,
              stack(
                hstack(iconImageView.withWidth(40).withHeight(40),
                       stack(headlineLabel, hstack(starRatingImageView.withWidth(100).withHeight(17), UIView())),
                       spacing: 8),
                bodyLabel,
                UIView(),
//                hstack(UIView(), priceLabel, storeLabel, callToActionButton, spacing: 12)
                hstack(callToActionButton.withHeight(39)).withMargins(.init(top: 0, left: 10, bottom: 10, right: 10))
                , spacing: 8
              ).withMargins(.allSides(10))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
