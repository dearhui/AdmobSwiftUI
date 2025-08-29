//
//  NativeAdBannerView.swift
//  
//
//  Created by minghui on 2023/6/15.
//

import GoogleMobileAds
import UIKit

class NativeAdBannerView: GoogleMobileAds.NativeAdView {
    
    let adTag: UILabel = UILabel(text: "AD", font: .systemFont(ofSize: 11, weight: .semibold), textColor: .white, textAlignment: .center)
    let headlineLabel = UILabel(text: "", font: .systemFont(ofSize: 15, weight: .medium), textColor: .label)
    let iconImageView = UIImageView()
    let bodyLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .secondaryLabel)
    let starRatingImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        self.headlineView = headlineLabel
        self.iconView = iconImageView
        self.bodyView = bodyLabel
        
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
        
        let headerStack = hstack([headlineLabel, adTag])
        let leftStack = stack(headerStack, bodyLabel)
        
        let mainStack = hstack([leftStack, iconImageView], spacing: 8).withMargins(.allSides(8))
        addSubview(mainStack)
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

