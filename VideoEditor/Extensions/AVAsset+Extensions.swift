//
//  AVAsset+Extensions.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 15/11/23.
//

import AVFoundation

extension AVAsset {
    var videoSize: CGSize {
        let tracks = self.tracks(withMediaType: AVMediaType.video)
        if (tracks.count > 0){
            let videoTrack = tracks[0]
            let size = videoTrack.naturalSize
            let txf = videoTrack.preferredTransform
            let realVidSize = size.applying(txf)
            return realVidSize
        }
        return CGSize(width: 0, height: 0)
    }
    
    var fullRange: CMTimeRange {
        return CMTimeRange(start: .zero, duration: duration)
    }
    
    func trimmedComposition(_ range: CMTimeRange) -> AVAsset {
        guard CMTimeRangeEqual(fullRange, range) == false else {return self}
        
        let composition = AVMutableComposition()
        try? composition.insertTimeRange(range, of: self, at: .zero)
        
        if let videoTrack = tracks(withMediaType: .video).first {
            composition.tracks.forEach {$0.preferredTransform = videoTrack.preferredTransform}
        }
        return composition
    }
}
