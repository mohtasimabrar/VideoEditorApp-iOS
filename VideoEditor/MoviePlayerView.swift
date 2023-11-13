//
//  MoviePlayerView.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 9/11/23.
//

import UIKit
import AVFoundation
import SDWebImage
import SwiftyGif
import Photos

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
    
    var videoFrameView = UIView()
    let gifImageView = SDAnimatedImageView()
    var gifName: String = ""
//    weak var imageView: GIFImageView!
//    var currentGIFName: String = "sticker1" {
//        didSet {
//            self.animate()
//        }
//    }
    
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
        videoFrameView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        self.addSubview(videoFrameView)
//        caLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
//        caLayer.backgroundColor = UIColor.red.cgColor
//        playerLayer.addSublayer(caLayer)
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
        
        let movieWidth = abs(player.currentItem!.asset.videoSize().width)
        let movieHeight = abs(player.currentItem!.asset.videoSize().height)
        
        //TODO: Might try this logic for freeform cropping
        if movieHeight > movieWidth {
            let width = (movieWidth * self.frame.height) / movieHeight
            let x = ((self.frame.width - width)/2)
            videoFrameView.frame = CGRect(x: x, y: 0, width: width, height: self.frame.height)
            gifImageView.frame = CGRect(x: Int(width) - 100, y: Int(self.frame.height) - 100, width: 100, height: 100)
        } else {
            let height = (movieHeight * self.frame.width) / movieWidth
            let y = ((self.frame.height - height)/2)
            videoFrameView.frame = CGRect(x: 0, y: y, width: self.frame.width, height: height)
            gifImageView.frame = CGRect(x: Int(self.frame.width) - 100, y: Int(height) - 100, width: 100, height: 100)
        }
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
    
    func playerStateChanged() {
        if player.timeControlStatus == .playing {
            pause()
        } else {
            play()
        }
        toggleAnimation()
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
    
    func toggleAnimation() {
        if gifImageView.isAnimating {
            gifImageView.stopAnimating()
        } else {
            gifImageView.startAnimating()
        }
    }
    
    func exportEditedVideo() {
        let asset = player.currentItem!.asset
        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            print("Something is wrong with the asset.")
            return
        }
        do {
            // 1
            let timeRange = CMTimeRange(start: startTrimTime, duration: endTrimTime)
            // 2
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
            // 3
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: audioAssetTrack,
                    at: .zero)
            }
        } catch {
            // 4
            print(error)
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        let videoSize: CGSize
        if videoInfo.isPortrait {
            videoSize = CGSize(
                width: assetTrack.naturalSize.height,
                height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
//        let gifLayer = CALayer()
//        gifLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        
        if let animation = animationForGif(gifName: gifName) {
            overlayLayer.add(animation, forKey: "contents")
        }
        
//        overlayLayer.addSublayer(gifLayer)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(
            for: compositionTrack,
            assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            print("Cannot create export session.")
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async { [weak self] in
                switch export.status {
                case .completed:
                    guard let self else {
                        return
                    }
                    self.exportVideoCompositionToPhotos(videoComposition: videoComposition, outputURL: exportURL)
                default:
                    print("Something went wrong during export.")
                    print(export.error ?? "unknown error")
                    
                    break
                }
            }
        }
        
        
    }
    
    func gifToCFData(gifName: String) -> CFData? {
        // Get the path of the GIF file in the bundle
        var name = gifName
        if let dotRange = name.range(of: ".") {
            name.removeSubrange(dotRange.lowerBound..<name.endIndex)
        }
        guard let gifPath = Bundle.main.path(forResource: name, ofType: "GIF") else {
            print("GIF file not found")
            return nil
        }
        
        // Create a UIImage from the GIF file
        guard let gifImage = UIImage(contentsOfFile: gifPath) else {
            print("Failed to create UIImage from GIF")
            return nil
        }
        
        // Convert the UIImage to NSData and then to CFData
        if let data = gifImage.sd_imageData(as: SDImageFormat.webP) {
            let cfData = NSData(data: data) as CFData
            return cfData
        }
        
        print("Failed to convert UIImage to CFData")
        return nil
    }
    
    func animationForGif(gifName: String) -> CAKeyframeAnimation? {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.contents))
        
        var frames: [CGImage] = []
        var delayTimes: [CGFloat] = []
        
        var totalTime: CGFloat = 0.0
        //        var gifWidth: CGFloat, gifHeight: CGFloat
        
        guard let gifSource = CGImageSourceCreateWithData(gifToCFData(gifName: gifName)!, nil) else {
            return nil
        }
        
        // get frame
        let frameCount = CGImageSourceGetCount(gifSource)
        
        for i in 0..<frameCount {
            guard let frame = CGImageSourceCreateImageAtIndex(gifSource, i, nil) else {
                continue
            }
            
            guard let dic = CGImageSourceCopyPropertiesAtIndex(gifSource, i, nil) as? [AnyHashable: Any] else { continue }
            //            gifWidth = dic[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
            //            gifHeight = dic[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
            
            guard let gifDic: [AnyHashable: Any] = dic[kCGImagePropertyGIFDictionary] as? [AnyHashable: Any] else { continue }
            let delayTime = gifDic[kCGImagePropertyGIFDelayTime] as? CGFloat ?? 0
            
            frames.append(frame)
            delayTimes.append(delayTime)
            
            totalTime += delayTime
        }
        
        if frames.count == 0 {
            return nil
        }
        
        assert(frames.count == delayTimes.count)
        
        var times: [NSNumber] = []
        var currentTime: CGFloat = 0
        
        for i in 0..<delayTimes.count {
            times.append(NSNumber(value: Double(currentTime / totalTime)))
            currentTime += delayTimes[i]
        }
        
        animation.keyTimes = times
        animation.values = frames
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = Double(totalTime)
        animation.repeatCount = .greatestFiniteMagnitude
        
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        
        return animation
    }
    
    func exportVideoCompositionToPhotos(videoComposition: AVMutableVideoComposition, outputURL: URL) {
        // Check if the Photos library is authorized
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            saveVideoCompositionToPhotosLibrary(videoComposition: videoComposition, outputURL: outputURL)
        } else {
            // If not authorized, request access
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.saveVideoCompositionToPhotosLibrary(videoComposition: videoComposition, outputURL: outputURL)
                } else {
                    // Handle the case where the user denies access to the Photos library
                    print("Access to Photos library denied")
                }
            }
        }
    }
    
    func saveVideoCompositionToPhotosLibrary(videoComposition: AVMutableVideoComposition, outputURL: URL) {
        // Create an AVAsset from the outputURL
        let asset = AVAsset(url: outputURL)
        
        PHPhotoLibrary.shared().performChanges({
            // Add the video file to the Photos library
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
        }) { success, error in
            if success {
                print("Video saved to Photos library successfully")
            } else {
                if let error = error {
                    print("Error saving video to Photos library: \(error.localizedDescription)")
                }
            }
        }
    }

    
    func getOutputURL() -> URL? {
        // Get the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // Create a unique filename for the output video
        let outputFilename = "output_video.mp4"
        let outputURL = documentsDirectory.appendingPathComponent(outputFilename)
        
        return outputURL
    }
    
    private func addGif(to layer: CALayer) {
        let image = gifImageView.image
        let imageLayer = CALayer()
        
        imageLayer.frame = gifImageView.frame
        
        imageLayer.contents = image?.cgImage
        layer.addSublayer(imageLayer)
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
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
            let txf = videoTrack.preferredTransform
            let realVidSize = size.applying(txf)
            print(videoTrack)
            print(txf)
            print(size)
            print(realVidSize)
            return realVidSize
        }
        return CGSize(width: 0, height: 0)
    }
}
