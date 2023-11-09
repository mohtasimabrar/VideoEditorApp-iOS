//
//  EditorViewController.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import Foundation
import UIKit

class EditorViewController: UIViewController {
    
    private lazy var playerButton: PlayerButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(didTapPlayerButton), for: .touchUpInside)
        $0.contentEdgeInsets = UIEdgeInsets(top: 5,left: 5,bottom: 5,right: 5)
        
        return $0
    }(PlayerButton())
    private lazy var playerView: MoviePlayerView? = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        return $0
    }(MoviePlayerView())
    
    private lazy var timelineSlider: UISlider = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(self.seekSliderValueChanged(_:)), for: .valueChanged)
        $0.addTarget(self, action: #selector(self.seekSliderTouchUp(_:)), for: .touchUpInside)
        
        return $0
    }(UISlider())
    
    var videoURL: URL?
    
    var activity: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    var playbackTimer: Timer?
    var isScrubbing: Bool = false
    
    deinit {
        print("EditorVC Deinit Called!!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        playerView?.movie = Movie(withURL: videoURL!)
        showActivity()
        playerButton.isEnabled = false
        playerView?.playerDidBecomeReady = { [weak self] () -> () in
            self?.playerView?.playerStateChanged()
            self?.showActivity()
            self?.playerButton.isEnabled = true
        }
        playbackTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop the video playback
        playerView?.player?.pause()
        playerView = nil
        playbackTimer?.invalidate()
    }
    
    private func setupView() {
        [playerButton, playerView!, timelineSlider].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            playerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            playerButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            playerButton.heightAnchor.constraint(equalToConstant: 50),
            playerButton.widthAnchor.constraint(equalToConstant: 50),
            
            timelineSlider.leadingAnchor.constraint(equalTo: playerButton.trailingAnchor, constant: 10),
            timelineSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            timelineSlider.topAnchor.constraint(equalTo: playerButton.topAnchor),
            timelineSlider.bottomAnchor.constraint(equalTo: playerButton.bottomAnchor),
            
            playerView!.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            playerView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView!.bottomAnchor.constraint(equalTo: playerButton.topAnchor),
            
        ])
    }
    
    @objc func updateSlider() {
        if !isScrubbing {
            let currentTime = playerView!.player!.currentTime().seconds
            let duration = playerView!.player!.currentItem?.duration.seconds ?? 1.0
            let progress = Float(currentTime / duration)
            timelineSlider.value = progress
        }
    }
    
    @objc func didTapPlayerButton(_ sender: Any) {
        playerButton.playerState.tap()
        playerView!.playerStateChanged()
    }
    
    @objc func seekSliderValueChanged(_ sender:UISlider!) {
        isScrubbing = true
        playerView!.seek(toSecond: Double(sender.value))
    }
    
    @objc func seekSliderTouchUp(_ sender: UISlider) {
        isScrubbing = false
    }
}

private extension EditorViewController {
    
    func showActivity() {
        view.addSubview(playerView!)
        activity.frame = playerView!.frame
        activity.startAnimating()
    }
    
    func hideActivity() {
        activity.stopAnimating()
        activity.removeFromSuperview()
    }
}
