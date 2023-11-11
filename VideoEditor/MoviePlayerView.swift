//
//  MoviePlayerView.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit
import AVFoundation

protocol MoviePlayetViewDelegate: AnyObject {
    func playerDidBecomeReady()
}

class MoviePlayerView: UIView {
    
    // asset that is to be played
    var movie: Movie
    
    weak var delegate: MoviePlayetViewDelegate?
    
    let caLayer = CALayer()
    var initialFrame: CGRect = CGRect.zero
    var touchOffset: CGPoint = CGPoint.zero
    
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
    
    // let this layers class work as AVPlayerLayer than normal CALayer
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    init(movie: Movie) {
        self.movie = movie
        super.init(frame: CGRectZero)
        self.backgroundColor = .black
        let playerItem = AVPlayerItem(asset: movie.asset)
        player = AVPlayer(playerItem: playerItem)
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: nil)
//        caLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
//        caLayer.backgroundColor = UIColor.red.cgColor
//        playerLayer.addSublayer(caLayer)
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
        
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            delegate?.playerDidBecomeReady()
        }
    }
    
    @objc func videoDidFinishPlaying() {
        player.seek(to: startTrimTime)
        player.play()
    }
    
    func playerStateChanged() {
        if player.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
    }
    
    func transformVideo() {
        let width = movie.asset.videoSize().height
        let cropRect = CGRect(x: 0, y: 0, width: width, height: width)
        let cropScaleComposition = AVMutableVideoComposition(asset: player.currentItem!.asset, applyingCIFiltersWithHandler: {request in
            
            let cropFilter = CIFilter(name: "CICrop")! //1
            cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey) //2
            cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
            
            
            let imageAtOrigin = cropFilter.outputImage!.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)) //3
            
            request.finish(with: imageAtOrigin, context: nil) //4
        })
        
        cropScaleComposition.renderSize = cropRect.size //5
        player.currentItem!.videoComposition = cropScaleComposition  //6
    }
    
}

//MARK: Player controls
extension MoviePlayerView {
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func seek(toSecond seconds: Double) {
        let time = CMTime(seconds: seconds * player.currentItem!.duration.seconds, preferredTimescale: movie.asset.duration.timescale)
        if time < startTrimTime {
            player.seek(to: startTrimTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//            player.seek(to: startTrimTime)
        } else {
            player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//            player.seek(to: time)
        }
    }
    
    func seekToStartTrim() {
        player.seek(to: startTrimTime)
    }
    
    func trimStart(startTime: Double) {
        if player.timeControlStatus == .playing {
            pause()
        }
        startTrimTime = CMTime(seconds: startTime * player.currentItem!.duration.seconds, preferredTimescale: player.currentItem!.duration.timescale)
        self.seek(toSecond: startTime)
    }
    
    func trimEnd(endTime: Double) {
        if player.timeControlStatus == .playing {
            pause()
        }
        endTrimTime = CMTime(seconds: endTime * player.currentItem!.duration.seconds, preferredTimescale: player.currentItem!.duration.timescale)
        self.seek(toSecond: endTime)
    }
    
    func setEndTrimTime() {
        player.currentItem!.forwardPlaybackEndTime = endTrimTime
        seekToStartTrim()
        play()
    }
    
}


extension AVAsset{
    func videoSize()->CGSize{
        let tracks = self.tracks(withMediaType: AVMediaType.video)
        if (tracks.count > 0){
            let videoTrack = tracks[0]
            let size = videoTrack.naturalSize
            print(size)
            return size
        }
        return CGSize(width: 0, height: 0)
    }
    
}
