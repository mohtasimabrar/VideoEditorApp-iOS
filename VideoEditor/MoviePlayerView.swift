//
//  MoviePlayerView.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit
import AVFoundation

class MoviePlayerView: UIView {
    
    // callback for player being ready
    var playerDidBecomeReady: (() -> ())?
    
    // asset that is to be played
    var movie: Movie? {
        didSet {
            addPlayer()
        }
    }
    
    // use view's layer as AVPlayerLayer to play the movie
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // player here should be AVPlayerLayer's player
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue  }
    }
    
    // let this layers class work as AVPlayerLayer than normal CALayer
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("MoviePlayerView Deinit Called!!")
        movie = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            playerDidBecomeReady?()
        }
    }
    
    @objc func videoDidFinishPlaying() {
        // Handle what should happen when the video finishes playing
        // For example, you can rewind the video to the beginning or remove the player view.
        player!.seek(to: CMTime.zero)
        player!.play() // Optionally, restart the video
    }
    
    func playerStateChanged() {
        if player?.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
    }
    
    func seek(toSecond seconds: Double) {
        let time = CMTime(seconds: seconds * player!.currentItem!.duration.seconds, preferredTimescale: movie!.asset.duration.timescale)
        player?.seek(to: time)
    }
    
}

private extension MoviePlayerView {
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func addPlayer()  {
        guard let _movie = movie else { return }
        let playerItem = AVPlayerItem(asset: _movie.asset)
        player = AVPlayer(playerItem: playerItem)
        addPlayerObservers(playerItem: playerItem)
    }
    
    func addPlayerObservers(playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: nil)
    }
    
}
