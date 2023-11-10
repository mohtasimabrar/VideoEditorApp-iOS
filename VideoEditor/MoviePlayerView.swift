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
        let playerItem = AVPlayerItem(asset: movie.asset)
        player = AVPlayer(playerItem: playerItem)
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MoviePlayerView Deinit Called!!")
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
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
            player.seek(to: startTrimTime)
        } else {
            player.seek(to: time)
        }
    }
    
    func seekToStartTrim() {
        player.seek(to: startTrimTime)
    }
    
    func trimStart(startTime: Double) {
        startTrimTime = CMTime(seconds: startTime * player.currentItem!.duration.seconds, preferredTimescale: player.currentItem!.duration.timescale)
        player.seek(to: startTrimTime)
    }
    
    func trimEnd(endTime: Double) {
//        if endTrimTime != CMTime.zero || player.currentItem!.forwardPlaybackEndTime != .invalid {
//            player.currentItem!.forwardPlaybackEndTime = .invalid
//        }
        endTrimTime = CMTime(seconds: endTime * player.currentItem!.duration.seconds, preferredTimescale: player.currentItem!.duration.timescale)
        player.seek(to: endTrimTime)
    }
    
    func setEndTrimTime() {
        player.currentItem!.forwardPlaybackEndTime = endTrimTime
    }
    
}
