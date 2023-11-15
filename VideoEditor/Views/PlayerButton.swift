//
//  PlayerButton.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit

enum PlayerButtonState {
    case play
    case pause
    case unknown // if player is not ready to play
    
    // tap will switch the state of the player
    mutating func tap() {
        switch self {
            case .play:
                self = .pause
            case .pause: 
                self = .play
            case .unknown: 
                break
        }
    }
    
}

class PlayerButton: UIButton {
    
    // set the images based on play/pause states of the player
    var playerState: PlayerButtonState = .unknown {
        didSet {
            switch self.playerState {
                case .pause: 
                    pause()
                case .play: 
                    play()
                default: 
                    break
            }
        }
    }
    
    // set player state to play when only it is ready to play
    override var isEnabled: Bool {
        didSet {
            self.playerState =  self.isEnabled ? .play : .unknown
        }
    }
    
    override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        playerState.tap()
    }
    
    func play() {
        setImage(UIImage(named: "pause_button"), for: .normal)
    }
    
    func pause() {
        setImage(UIImage(named: "play_button"), for: .normal)
    }
    
}
