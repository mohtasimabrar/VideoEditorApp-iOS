//
//  ExportViewController.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 15/11/23.
//

import Foundation
import AVFoundation
import UIKit
import Photos
import SDWebImage

class ExportViewController: UIViewController {
    
    let viewModel: ExportViewModel
    
    private lazy var statusLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.textColor = .gray
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        return $0
    }(UILabel())
    
    private lazy var loaderGifImageView: SDAnimatedImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        let animatedImage = SDAnimatedImage(named: "loader.GIF")
        $0.contentMode = .scaleAspectFit
        $0.image = animatedImage
        $0.startAnimating()
        
        return $0
    }(SDAnimatedImageView())
    
    init(viewModel: ExportViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        view.backgroundColor = UIColor(hex: "#F7F7F7")
        setupView()
        statusLabel.text = "Exporting..."
        viewModel.exportEditedVideo()
    }
    
    private func setupView() {
        view.addSubview(statusLabel)
        view.addSubview(loaderGifImageView)
        
        NSLayoutConstraint.activate([
            loaderGifImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loaderGifImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor,  constant: -50),
            loaderGifImageView.widthAnchor.constraint(equalToConstant: 300),
            loaderGifImageView.heightAnchor.constraint(equalToConstant: 200),
            
            statusLabel.topAnchor.constraint(equalTo: loaderGifImageView.bottomAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

//MARK: ExportViewModelDelegate methods
extension ExportViewController: ExportViewModelDelegate {
    func exportCompleted() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Exported!"
            DispatchQueue.main.asyncAfter(deadline:.now() + 1) {
                self.loaderGifImageView.stopAnimating()
                self.dismiss(animated: true)
            }
        }
    }
}
