//
//  GifCollectionViewCell.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 12/11/23.
//

import Foundation
import UIKit
import SDWebImage

class GifCollectionViewCell: UICollectionViewCell {
    
    var imageView: SDAnimatedImageView = SDAnimatedImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func addGif(_ name: String) {
        imageView = SDAnimatedImageView(image: SDAnimatedImage(named: "\(name)"))
        imageView.startAnimating()
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}





