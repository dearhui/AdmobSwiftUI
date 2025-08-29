//
//  File.swift
//  
//
//  Created by minghui on 2023/6/15.
//

import GoogleMobileAds
import UIKit

class NativeAdCardView: GoogleMobileAds.NativeAdView {
    
    let adTag: UILabel = UILabel(text: "AD", font: .systemFont(ofSize: 10, weight: .semibold), textColor: .white)
    let headlineLabel = UILabel(text: "", font: .systemFont(ofSize: 17, weight: .medium), textColor: .label)
    let myMediaView = GoogleMobileAds.MediaView()
    let callToActionButton = UIButton(title: "", titleColor: .white, font: .boldSystemFont(ofSize: 18), backgroundColor: UIColor(hex: "#3871E0"), target: nil, action: nil)
    let iconImageView = UIImageView()
    let bodyLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .label)
    let starRatingImageView = UIImageView()
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
        
        adTag.withWidth(25)
        adTag.textAlignment = .center
        adTag.backgroundColor = .orange
        adTag.layer.cornerRadius = 2
        adTag.clipsToBounds = true
        adTag.text = NSLocalizedString("AD", bundle: .module, comment: "Ad tag label")
        
        // avoid star width to long add space view
        let starRattingStack = hstack([adTag, starRatingImageView, advertiserLabel, UIView()], spacing: 4)
        let headlineStarStack = stack(headlineLabel, starRattingStack, spacing: 8)
        // avoid ad validator when icon hidden add stack and space view
        let iconStack = stack(iconImageView)
        let iconHeadlineStack = hstack([iconStack, headlineStarStack, UIView()], spacing: 8)
        let buttonContainer = hstack([callToActionButton.withHeight(39)]).withMargins(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        let bottomStack = stack(iconHeadlineStack, bodyLabel, buttonContainer, spacing: 8).withMargins(.allSides(10))
        let mainStack = stack(myMediaView, bottomStack)
        
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
