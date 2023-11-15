//
//  EditorViewController.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import Foundation
import UIKit
import SDWebImage
import AVFoundation

class EditorViewController: UIViewController {
    
    private var movie: Movie
    
    private var gifList = ["wow.GIF", "hello.GIF", "handwash.GIF", "glasses.GIF", "laugh.GIF", "whatever.GIF", "angry.GIF", "blush.GIF", "confused.GIF", "hugs.GIF", "love.GIF", "loved.GIF", "sad.GIF", "annoyed.GIF", "senti.GIF", "sleep.GIF", "wink.GIF"]
    
    private lazy var playerButton: PlayerButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(self, action: #selector(didTapPlayerButton), for: .touchUpInside)
        $0.contentEdgeInsets = UIEdgeInsets(top: 5,left: 5,bottom: 5,right: 5)
        
        return $0
    }(PlayerButton())
    
    private lazy var cropButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(UIImage(systemName: "square.dashed"), for: .normal)
        $0.setTitleColor(.black, for: .normal)
        $0.addTarget(self, action: #selector(didTapCropButton), for: .touchUpInside)
        
        return $0
    }(UIButton())
    
    private lazy var playerView: MoviePlayerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.delegate = self
        $0.endTrimTime = movie.asset.fullRange.end
        
        return $0
    }(MoviePlayerView(asset: movie.asset))
    
    private lazy var timelineControlView: VideoTrimmer = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.minimumDuration = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        $0.asset = movie.asset
        $0.addTarget(self, action: #selector(didBeginTrimming(_:)), for: VideoTrimmer.didBeginTrimming)
        $0.addTarget(self, action: #selector(didEndTrimming(_:)), for: VideoTrimmer.didEndTrimming)
        $0.addTarget(self, action: #selector(selectedRangeDidChanged(_:)), for: VideoTrimmer.selectedRangeChanged)
        $0.addTarget(self, action: #selector(didBeginScrubbing(_:)), for: VideoTrimmer.didBeginScrubbing)
        $0.addTarget(self, action: #selector(didEndScrubbing(_:)), for: VideoTrimmer.didEndScrubbing)
        $0.addTarget(self, action: #selector(progressDidChanged(_:)), for: VideoTrimmer.progressChanged)
        
        return $0
    }(VideoTrimmer())
    
    private lazy var trimTimeLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.textColor = .gray
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        return $0
    }(UILabel())
    
    private lazy var durationLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.textColor = .gray
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        return $0
    }(UILabel())
    
    private lazy var stickerLabel: UILabel = {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .light)
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.textColor = .darkGray
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = "Animated Stickers"
        
        return $0
    }(UILabel())
    
    private lazy var scrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alwaysBounceHorizontal = true
        $0.alwaysBounceVertical = false
        $0.isDirectionalLockEnabled = true
        $0.isScrollEnabled = true
        $0.showsHorizontalScrollIndicator = false
        
        return $0
    }(UIScrollView())
    
    private lazy var gifStackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.alignment = .leading
        $0.distribution = .fillProportionally
        $0.axis = .horizontal
        $0.spacing = 5
        
        return $0
    }(UIStackView())
    
    private var asset: AVAsset {
        movie.asset
    }
    
    private var player: AVPlayer {
        playerView.player
    }
    
    init(videoURL: URL) {
        self.movie = Movie(withURL: videoURL)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("EditorVC Deinit Called!!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "TRIM"
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "#9B5AFA")
        setupView()
        playerButton.isEnabled = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportTapped))
        
        player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            guard let self = self else {return}
            self.timelineControlView.progress = time
        }
        
        for (index,image) in gifList.enumerated() {
            let imageView = SDAnimatedImageView()
            let animatedImage = SDAnimatedImage(named: "\(image)")
            imageView.contentMode = .scaleAspectFit
            imageView.image = animatedImage
            imageView.startAnimating()
            imageView.tag = index
            imageView.isUserInteractionEnabled = true
            imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
            gifStackView.addArrangedSubview(imageView)
        }
        
        gifStackView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapScrollView))
        gifStackView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.largeTitleDisplayMode = .never
        let yourBackImage = UIImage(systemName: "xmark")
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = yourBackImage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerView.pause()
    }
    
    private func setupView() {
        [playerButton, playerView, timelineControlView, trimTimeLabel, durationLabel, cropButton, scrollView, stickerLabel].forEach { view.addSubview($0) }
        
        scrollView.addSubview(gifStackView)
        
        NSLayoutConstraint.activate([
            
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 60),
            
            gifStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            gifStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            gifStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            stickerLabel.bottomAnchor.constraint(equalTo: scrollView.topAnchor, constant: -2),
            stickerLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stickerLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            timelineControlView.bottomAnchor.constraint(equalTo: stickerLabel.topAnchor, constant: -50),
            timelineControlView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            timelineControlView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            timelineControlView.heightAnchor.constraint(equalToConstant: 60),
            
            playerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            playerButton.bottomAnchor.constraint(equalTo: timelineControlView.topAnchor, constant: -20),
            playerButton.heightAnchor.constraint(equalToConstant: 50),
            playerButton.widthAnchor.constraint(equalToConstant: 50),
            
            trimTimeLabel.topAnchor.constraint(equalTo: playerButton.topAnchor),
            trimTimeLabel.leadingAnchor.constraint(equalTo: playerButton.trailingAnchor),
            trimTimeLabel.trailingAnchor.constraint(equalTo: durationLabel.trailingAnchor),
            trimTimeLabel.heightAnchor.constraint(equalToConstant: 25),
            
            durationLabel.topAnchor.constraint(equalTo: trimTimeLabel.bottomAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: playerButton.trailingAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: cropButton.leadingAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: playerButton.bottomAnchor),
            
            cropButton.topAnchor.constraint(equalTo: playerButton.topAnchor),
            cropButton.bottomAnchor.constraint(equalTo: playerButton.bottomAnchor),
            cropButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cropButton.widthAnchor.constraint(equalToConstant: 50),
            
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerButton.topAnchor, constant: -20),
            
        ])
    }
    
    @objc func exportTapped() {
        let exportVM = ExportViewModel(asset: self.movie.asset.trimmedComposition(self.timelineControlView.selectedRange), gifName: self.playerView.gifName)
        let exportVC = ExportViewController(viewModel: exportVM)
        
        exportVC.modalPresentationStyle = .custom
        exportVC.transitioningDelegate = self
        playerView.pause()
        self.present(exportVC, animated: true, completion: nil)
    }
    
    @objc func tapScrollView(sender: UITapGestureRecognizer) {
        for imageView in self.gifStackView.subviews{
            let location = sender.location(in: imageView)
            if let hitImageView = imageView.hitTest(location, with: nil) {
                playerView.updateGifImageView(gifList[hitImageView.tag])
            }
        }
    }
    
    @objc func didTapPlayerButton(_ sender: Any) {
        playerView.playerStateChanged()
    }
    
    @objc func didTapCropButton(_sender: Any) {
        playerView.transformVideo()
    }
    
    private func setLabels() {
        trimTimeLabel.text = "\(timelineControlView.selectedRange.start.displayString) ~ \(timelineControlView.selectedRange.end.displayString)s"
    }
    
}

//MARK: MoviePlayerViewDelegate methods
extension EditorViewController: MoviePlayetViewDelegate {
    func playerStartedPlaying() {
        playerButton.playerState = .play
    }
    
    func playerPausedPlaying() {
        playerButton.playerState = .pause
    }
    
    func playerDidBecomeReady() {
        self.playerView.playerStateChanged()
        self.playerButton.isEnabled = true
        setLabels()
        durationLabel.text = "Maximum \(Double(round(100 * (playerView.player.currentItem?.duration.seconds ?? 0.0))) / 100) sec"
    }
}

//MARK: Timeline related methods
extension EditorViewController {
    @objc private func didBeginTrimming(_ sender: VideoTrimmer) {
        playerView.startedTrimming()
    }
    
    @objc private func didEndTrimming(_ sender: VideoTrimmer) {
        setLabels()
        playerView.endedTrimming(timeRange: timelineControlView.selectedRange)
    }
    
    @objc private func selectedRangeDidChanged(_ sender: VideoTrimmer) {
        setLabels()
        playerView.trimming(timeRange: timelineControlView.selectedRange, state: timelineControlView.trimmingState)
    }
    
    @objc private func didBeginScrubbing(_ sender: VideoTrimmer) {
        playerView.pause()
    }
    
    @objc private func didEndScrubbing(_ sender: VideoTrimmer) {
        playerView.play()
    }
    
    @objc private func progressDidChanged(_ sender: VideoTrimmer) {
        let time = CMTimeSubtract(timelineControlView.progress, timelineControlView.selectedRange.start)
        playerView.seek(to: time)
    }
}

//MARK: UIViewControllerTransitioningDelegate methods
extension EditorViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
