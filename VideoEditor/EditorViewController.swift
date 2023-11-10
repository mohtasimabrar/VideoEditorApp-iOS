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
    
    private lazy var playerView: MoviePlayerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.delegate = self
        
        return $0
    }(MoviePlayerView(movie: Movie(withURL: videoURL)))
    
    private lazy var timelineSlider: UISlider = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(self.seekSliderValueChanged(_:)), for: .valueChanged)
        $0.addTarget(self, action: #selector(self.seekSliderTouchUp(_:)), for: .touchUpInside)
        
        return $0
    }(UISlider())
    
    private lazy var startTrimSlider: UISlider = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(self.startTrimSliderValueChanged(_:)), for: .valueChanged)
        
        return $0
    }(UISlider())
    
    private lazy var endTrimSlider: UISlider = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(self.endTrimSliderValueChanged(_:)), for: .valueChanged)
        $0.addTarget(self, action: #selector(self.endTrimSliderTouchUp(_:)), for: .touchUpInside)
        $0.value = 1.0
        
        return $0
    }(UISlider())
    
    private lazy var playbackTimer: Timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    
    var isScrubbing: Bool = false
    
    var videoURL: URL
    var durationOfVideo: Double = 0.0
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
        self.durationOfVideo = playerView.player.currentItem?.duration.seconds ?? 0.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("EditorVC Deinit Called!!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        playerButton.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop the video playback
        playerView.player.pause()
        playbackTimer.invalidate()
    }
    
    private func setupView() {
        [playerButton, playerView, timelineSlider, startTrimSlider, endTrimSlider].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            endTrimSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            endTrimSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            endTrimSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            endTrimSlider.heightAnchor.constraint(equalToConstant: 50),
            
            startTrimSlider.bottomAnchor.constraint(equalTo: endTrimSlider.topAnchor, constant: -10),
            startTrimSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            startTrimSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            startTrimSlider.heightAnchor.constraint(equalToConstant: 50),
            
            timelineSlider.bottomAnchor.constraint(equalTo: startTrimSlider.topAnchor, constant: -10),
            timelineSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            timelineSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            timelineSlider.heightAnchor.constraint(equalToConstant: 50),
            
            playerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerButton.bottomAnchor.constraint(equalTo: timelineSlider.topAnchor, constant: -10),
            playerButton.heightAnchor.constraint(equalToConstant: 50),
            playerButton.widthAnchor.constraint(equalToConstant: 50),
            
            playerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerButton.topAnchor, constant: -20),
            
        ])
    }
    
    @objc func didTapPlayerButton(_ sender: Any) {
        playerButton.playerState.tap()
        playerView.playerStateChanged()
    }
    
}

extension EditorViewController: MoviePlayetViewDelegate {
    func playerDidBecomeReady() {
        self.playerView.playerStateChanged()
        self.playerButton.isEnabled = true
        playbackTimer.fire()
    }
}

//MARK: Timeline methods
extension EditorViewController {
    @objc func updateSlider() {
        if !isScrubbing {
            let currentTime = playerView.player.currentTime().seconds
//            print(currentTime)
            let duration = playerView.player.currentItem?.duration.seconds ?? 1.0
//            print(duration)
            let progress = Float(currentTime / duration)
            timelineSlider.setValue(progress, animated: true)
        }
    }
    
    @objc func seekSliderValueChanged(_ sender:UISlider!) {
        isScrubbing = true
        playerView.seek(toSecond: Double(sender.value))
    }
    
    @objc func seekSliderTouchUp(_ sender: UISlider) {
        isScrubbing = false
    }
    
    @objc func startTrimSliderValueChanged(_ sender:UISlider) {
        playerView.trimStart(startTime: Double(sender.value))
    }
    
    @objc func endTrimSliderValueChanged(_ sender:UISlider) {
        playerView.trimEnd(endTime: Double(sender.value))
    }
    
    @objc func endTrimSliderTouchUp(_ sender: UISlider) {
        playerView.setEndTrimTime()
    }
}
