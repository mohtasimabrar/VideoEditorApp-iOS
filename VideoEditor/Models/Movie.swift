//
//  Movie.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//


import Foundation
import AVFoundation

class Movie {
    
    var asset: AVAsset
    var videoPath: URL
    
    init(withURL url: URL) {
        self.videoPath = url
        self.asset = AVURLAsset(url: url)
    }
}
