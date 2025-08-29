//
//  UIView+Extensions.swift
//  
//
//  Created by Claude on AdmobSwiftUI optimization
//

import UIKit

// MARK: - UIView Extensions to replace LBTATools functionality
extension UIView {
    
    @discardableResult
    func withWidth(_ width: CGFloat) -> UIView {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
        return self
    }
    
    @discardableResult
    func withHeight(_ height: CGFloat) -> UIView {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
        return self
    }
    
    @discardableResult
    func withMargins(_ margins: UIEdgeInsets) -> UIView {
        let containerView = UIView()
        containerView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor, constant: margins.top),
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margins.left),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margins.right),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -margins.bottom)
        ])
        
        return containerView
    }
}

// MARK: - UIEdgeInsets Extensions
extension UIEdgeInsets {
    static func allSides(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
    }
}

// MARK: - UILabel Convenience Initializer
extension UILabel {
    convenience init(text: String = "", font: UIFont = .systemFont(ofSize: 17), textColor: UIColor = .label, textAlignment: NSTextAlignment = .left, numberOfLines: Int = 1) {
        self.init()
        self.text = text
        self.font = font
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.numberOfLines = numberOfLines
    }
}

// MARK: - UIButton Convenience Initializer
extension UIButton {
    convenience init(title: String, titleColor: UIColor = .label, font: UIFont = .systemFont(ofSize: 17), backgroundColor: UIColor = .clear, target: Any? = nil, action: Selector? = nil) {
        self.init(type: .system)
        setTitle(title, for: .normal)
        setTitleColor(titleColor, for: .normal)
        titleLabel?.font = font
        self.backgroundColor = backgroundColor
        if let target = target, let action = action {
            addTarget(target, action: action, for: .touchUpInside)
        }
    }
}

// MARK: - Stack View Helper Functions
func stack(_ views: UIView..., axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 0, alignment: UIStackView.Alignment = .fill, distribution: UIStackView.Distribution = .fill) -> UIStackView {
    let stackView = UIStackView(arrangedSubviews: views)
    stackView.axis = axis
    stackView.spacing = spacing
    stackView.alignment = alignment
    stackView.distribution = distribution
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
}

func hstack(_ views: UIView..., spacing: CGFloat = 0, alignment: UIStackView.Alignment = .fill, distribution: UIStackView.Distribution = .fill) -> UIStackView {
    return stack(views[0], axis: .horizontal, spacing: spacing, alignment: alignment, distribution: distribution)
}

// Handle multiple views for hstack
func hstack(_ views: [UIView], spacing: CGFloat = 0, alignment: UIStackView.Alignment = .fill, distribution: UIStackView.Distribution = .fill) -> UIStackView {
    let stackView = UIStackView(arrangedSubviews: views)
    stackView.axis = .horizontal
    stackView.spacing = spacing
    stackView.alignment = alignment
    stackView.distribution = distribution
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
}