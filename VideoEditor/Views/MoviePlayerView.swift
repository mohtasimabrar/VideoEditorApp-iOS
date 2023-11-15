//
//  MoviePlayerView.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit
import AVFoundation
import SDWebImage
import Photos

protocol MoviePlayetViewDelegate: AnyObject {
    func playerDidBecomeReady()
    func playerStartedPlaying()
    func playerPausedPlaying()
}

class MoviePlayerView: UIView {
    
    weak var delegate: MoviePlayetViewDelegate?
    
    private var initialFrame: CGRect = CGRect.zero
    private var touchOffset: CGPoint = CGPoint.zero
    
    // use view's layer as AVPlayerLayer to play the movie
    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else {
            return AVPlayerLayer()
        }
        return layer
    }
    
    // player here should be AVPlayerLayer's player
    var player: AVPlayer {
        get { return playerLayer.player ?? AVPlayer() }
        set { playerLayer.player = newValue  }
    }
    
    var startTrimTime: CMTime = CMTime.zero
    var endTrimTime: CMTime = CMTime.zero
    
    private var videoFrameView = UIView()
    private let gifImageView = SDAnimatedImageView()
    var gifName: String = ""
    private var wasPlaying = false
    
    // let this layers class work as AVPlayerLayer than normal CALayer
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    init(asset: AVAsset) {
        super.init(frame: CGRectZero)
        self.backgroundColor = .black
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: nil)
        videoFrameView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        self.addSubview(videoFrameView)
        videoFrameView.addSubview(gifImageView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MoviePlayerView Deinit Called!!")
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setGifFrame()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            delegate?.playerDidBecomeReady()
        }
    }
    
    @objc func videoDidFinishPlaying() {
        player.seek(to: startTrimTime)
        play()
    }
    
    private func setGifFrame() {
        guard let item = player.currentItem else {
            return
        }
        let movieWidth = abs(item.asset.videoSize.width)
        let movieHeight = abs(item.asset.videoSize.height)
        
        //TODO: Kept the layer on top of video to try to use it for freeform cropping
        if movieHeight > movieWidth {
            let width = (movieWidth * self.frame.height) / movieHeight
            let padding: Int = Int(width) / 40
            let x = ((self.frame.width - width)/2)
            videoFrameView.frame = CGRect(x: x, y: 0, width: width, height: self.frame.height)
            gifImageView.frame = CGRect(x: Int(width) - Int(width/3.0) - padding, y: Int(self.frame.height) - Int(width/3.0) - padding, width: Int(width/3.0), height: Int(width/3.0))
        } else {
            let height = (movieHeight * self.frame.width) / movieWidth
            let padding: Int = Int(height) / 40
            let y = ((self.frame.height - height)/2)
            videoFrameView.frame = CGRect(x: 0, y: y, width: self.frame.width, height: height)
            gifImageView.frame = CGRect(x: Int(self.frame.width) - Int(height/3.0) - padding, y: Int(height) - Int(height/3.0) - padding, width: Int(height/3.0), height: Int(height/3.0))
        }
    }
    
    func updateGifImageView(_ gifName: String) {
        self.gifName = gifName
        let animatedImage = SDAnimatedImage(named: "\(gifName)")
        gifImageView.contentMode = .scaleAspectFit
        gifImageView.image = animatedImage
        if player.timeControlStatus == .playing {
            gifImageView.startAnimating()
        } else {
            gifImageView.stopAnimating()
        }
    }
}

//MARK: Cropping related methods
extension MoviePlayerView {
    func transformVideo() {
        let width = player.currentItem?.asset.videoSize.height
        let cropRect = CGRect(x: 0, y: 0, width: width ?? 0.0, height: width ?? 0.0)
        let cropScaleComposition = AVMutableVideoComposition(asset: player.currentItem?.asset ?? AVAsset(), applyingCIFiltersWithHandler: { request in
            if let cropFilter = CIFilter(name: "CICrop") {
                cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey)
                cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
                
                if let imageAtOrigin = cropFilter.outputImage?.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)) {
                    request.finish(with: imageAtOrigin, context: nil)
                }
            }
        })
        
        cropScaleComposition.renderSize = cropRect.size
        if let item = player.currentItem {
            item.videoComposition = cropScaleComposition
        }
    }
}

//MARK: Player controls
extension MoviePlayerView {
    func playerStateChanged() {
        if player.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
    }

    func play() {
        player.play()
        delegate?.playerStartedPlaying()
        gifImageView.startAnimating()
    }
    
    func pause() {
        player.pause()
        delegate?.playerPausedPlaying()
        gifImageView.stopAnimating()
    }
    
    func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    func seekToStartTrim() {
        seek(to: startTrimTime)
    }
    
    func startedTrimming() {
        if player.timeControlStatus == .playing {
            wasPlaying = true
            pause()
        } else {
            wasPlaying = false
        }
    }
    
    func trimming(timeRange: CMTimeRange, state: TrimmingState) {
        if state == .leading {
            self.seek(to: timeRange.start)
        } else if state == .trailing {
            self.seek(to: timeRange.end)
        }
    }
    
    func endedTrimming(timeRange: CMTimeRange) {
        guard let item = player.currentItem else {
            return
        }
        startTrimTime = timeRange.start
        endTrimTime = timeRange.end
        item.forwardPlaybackEndTime = endTrimTime
        seekToStartTrim()
        if wasPlaying {
            play()
        }
    }
}
