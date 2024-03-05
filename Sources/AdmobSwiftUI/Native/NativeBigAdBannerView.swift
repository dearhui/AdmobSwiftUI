//
//  NativeBigAdBannerView.swift
//
//
//  Created by minghui on 2024/3/5.
//

import GoogleMobileAds
import UIKit
import LBTATools

class NativeBigAdBannerView: GADNativeAdView {
    
    let adTag: UILabel = UILabel(text: "AD", font: .systemFont(ofSize: 10, weight: .semibold), textColor: .secondaryLabel, textAlignment: .center)
    let headlineLabel = UILabel(text: "", font: .systemFont(ofSize: 15, weight: .medium), textColor: .label)
    let bodyLabel = UILabel(text: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: .secondaryLabel)
    let starRatingImageView = UIImageView()
    let myMediaView = GADMediaView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        self.headlineView = headlineLabel
        self.bodyView = bodyLabel
        self.mediaView = myMediaView
        
        // 設定 media view 的最小尺寸
        myMediaView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        myMediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        myMediaView.contentMode = .scaleAspectFill
        myMediaView.clipsToBounds = true

        headlineLabel.numberOfLines = 2
        headlineLabel.lineBreakMode = .byWordWrapping

        bodyLabel.numberOfLines = 3
        bodyLabel.lineBreakMode = .byWordWrapping

        let leftStack = stack(headlineLabel, bodyLabel).withMargins(.init(top: 18, left: 8, bottom: 8, right: 8))

        hstack(myMediaView,leftStack, spacing: 8)
        
        addSubview(adTag)
        
        // add tag to bottom and trailing
        adTag.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adTag.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            adTag.leadingAnchor.constraint(equalTo: myMediaView.trailingAnchor, constant: 2),
            adTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 25),
            adTag.heightAnchor.constraint(equalToConstant: 18)
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
