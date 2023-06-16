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
    let starRatingImageView = UIImageView()
    
//    let storeLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)
//    let priceLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)
    let advertiserLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        self.headlineView = headlineLabel
        
        self.advertiserView = advertiserLabel
        
        myMediaView.translatesAutoresizingMaskIntoConstraints = false
        myMediaView.heightAnchor.constraint(equalTo: myMediaView.widthAnchor, multiplier: 9.0/16.0).isActive = true
        self.mediaView = myMediaView
        
        callToActionButton.isUserInteractionEnabled = false
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.clipsToBounds = true
        self.callToActionView = callToActionButton
        
        iconImageView.layer.cornerRadius = 4
        iconImageView.clipsToBounds = true
        iconImageView.withWidth(40).withHeight(40)
        self.iconView = iconImageView
        
        bodyLabel.numberOfLines = 2
        bodyLabel.isUserInteractionEnabled = false
        bodyLabel.textColor = .secondaryLabel
        self.bodyView = bodyLabel
        
        starRatingImageView.withWidth(100).withHeight(17)
        self.starRatingView = starRatingImageView
        
        adTag.withWidth(20)
        adTag.textAlignment = .center
        adTag.backgroundColor = .orange
        adTag.layer.cornerRadius = 2
        adTag.clipsToBounds = true
        
        // avoid star width to long add space view
        let starRattingStack = hstack(adTag, starRatingImageView, advertiserLabel, UIView(), spacing: 4)
        let headlineStarStack = stack(headlineLabel, starRattingStack, spacing: 8)
        // avoid ad validator when icon hidden add stack and space view
        let iconHeadlineStack = hstack(stack(iconImageView), headlineStarStack, UIView(), spacing: 8)
        let buttonStack = hstack(callToActionButton.withHeight(39)).withMargins(.init(top: 0, left: 10, bottom: 0, right: 10))
        let bottomStack = stack(iconHeadlineStack, bodyLabel, buttonStack, spacing: 8).withMargins(.allSides(10))
        stack(myMediaView, bottomStack)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
