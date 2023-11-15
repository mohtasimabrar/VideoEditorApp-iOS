//
//  VideoTrimmerThumb.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 15/11/23.
//

import UIKit

class VideoTrimmerThumb: UIView {
    var isActive = false
    
    var leadingChevronView = UIView()
    var trailingChevronView = UIView()
    
    var wrapperView = UIView()
    var leadingView = UIView()
    var trailingView = UIView()
    var topView = UIView()
    var bottomView = UIView()
    
    let leadingGrabber = UIControl()
    let trailingGrabber = UIControl()
    
    let chevronWidth = CGFloat(16)
    let edgeHeight = CGFloat(6)
    
    // MARK: - Input
    @objc private func x(_ sender: Any) {
        
    }
    
    // MARK: - Private
    private func updateColor() {
        let color = UIColor(hex: "#9B5AFA")
        leadingView.backgroundColor = color
        trailingView.backgroundColor = color
        topView.backgroundColor = color
        bottomView.backgroundColor = color
    }
    
    private func setup() {
        
        leadingChevronView.backgroundColor = .white
        trailingChevronView.backgroundColor = .white
        
        leadingView.layer.cornerRadius = 6
        leadingView.layer.cornerCurve = .continuous
        leadingView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        
        trailingView.layer.cornerRadius = 6
        trailingView.layer.cornerCurve = .continuous
        trailingView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        
        leadingView.addSubview(leadingChevronView)
        trailingView.addSubview(trailingChevronView)
        
        //        wrapperView.layer.shadowColor = UIColor.black.cgColor
        //        wrapperView.layer.shadowOffset = .zero
        //        wrapperView.layer.shadowRadius = 2
        //        wrapperView.layer.shadowOpacity = 0.25
        
        wrapperView.addSubview(leadingView)
        wrapperView.addSubview(trailingView)
        wrapperView.addSubview(topView)
        wrapperView.addSubview(bottomView)
        addSubview(wrapperView)
        
        wrapperView.addSubview(leadingGrabber)
        wrapperView.addSubview(trailingGrabber)
        
        updateColor()
    }
    
    
    
    // MARK: - UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = bounds.size
        
        wrapperView.frame = CGRect(origin: .zero, size: size)
        
        leadingView.frame = CGRect(x: 0, y: 0, width: chevronWidth, height: bounds.height)
        trailingView.frame = CGRect(x: bounds.width - chevronWidth, y: 0, width: chevronWidth, height: bounds.height)
        topView.frame = CGRect(x: chevronWidth, y: 0, width: bounds.width - chevronWidth * 2, height: edgeHeight)
        bottomView.frame = CGRect(x: chevronWidth, y: bounds.height - edgeHeight, width: bounds.width - chevronWidth * 2, height: edgeHeight)
        
        let chevronHorizontalInset = CGFloat(7)
        let chevronVerticalInset = CGFloat(16)
        let chevronFrame = CGRect(x: chevronHorizontalInset, y: chevronVerticalInset, width: chevronWidth - chevronHorizontalInset * 2, height: size.height - chevronVerticalInset * 2)
        
        leadingChevronView.frame = chevronFrame
        trailingChevronView.frame = chevronFrame
        
        leadingGrabber.frame = leadingView.frame
        trailingGrabber.frame = trailingView.frame
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}


