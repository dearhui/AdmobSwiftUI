//
//  NativeAdBannerView.swift
//  
//
//  Created by minghui on 2023/6/15.
//

import GoogleMobileAds
import UIKit
import LBTATools

class NativeAdBannerView: GADNativeAdView {
    
    let adTag: UILabel = UILabel(text: "AD", font: .systemFont(ofSize: 11, weight: .semibold), textColor: .white, textAlignment: .center)
    let headlineLabel = UILabel(text: "", font: .systemFont(ofSize: 15, weight: .medium), textColor: .label)
    let callToActionButton = UIButton(title: "", titleColor: .white, font: .boldSystemFont(ofSize: 14), backgroundColor: UIColor(hex: "#3871E0"), target: nil, action: nil)
    let iconImageView = UIImageView()
    let bodyLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .secondaryLabel)
    let starRatingImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        self.headlineView = headlineLabel
        self.callToActionView = callToActionButton
        self.iconView = iconImageView
        self.bodyView = bodyLabel
        
        callToActionButton.layer.cornerRadius = 8
        
        adTag.withWidth(20)
        adTag.backgroundColor = .orange
        adTag.layer.cornerRadius = 2
        adTag.clipsToBounds = true
        
        // config 1:1
        iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor, multiplier: 1).isActive = true
        iconImageView.layer.cornerRadius = 4
        iconImageView.clipsToBounds = true
        
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byWordWrapping
        
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byWordWrapping
        
        hstack(
            stack(hstack(headlineLabel, adTag, distribution: .fillProportionally),
                  bodyLabel),
            iconImageView, spacing: 8
        ).withMargins(.allSides(8))
        
        headlineLabel.isUserInteractionEnabled = false
        adTag.isUserInteractionEnabled = false
        bodyLabel.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

