//
//  ExportViewModel.swift
//  VideoEditor
//
//  Created by Mohtasim Abrar Samin on 15/11/23.
//

import Foundation
import AVFoundation
import Photos
import UIKit

protocol ExportViewModelDelegate: AnyObject {
    func exportCompleted()
}

class ExportViewModel {
    
    weak var delegate: ExportViewModelDelegate?
    
    func exportEditedVideo(asset: AVAsset, gifName: String) {
        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            print("Something is wrong with the asset.")
            return
        }
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
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
        overlayLayer.contentsGravity = .resizeAspect
        
        if videoSize.height > videoSize.width {
            let gifWidth = videoSize.width/3
            let gifHeight = videoSize.width/3
            let padding = videoSize.width / 40
            overlayLayer.frame = CGRect(x: videoSize.width - gifWidth - CGFloat(padding), y: CGFloat(padding), width: gifWidth, height: gifHeight)
        } else {
            let gifWidth = videoSize.height/3
            let gifHeight = videoSize.height/3
            let padding = videoSize.height / 40
            overlayLayer.frame = CGRect(x: videoSize.width - gifWidth - CGFloat(padding), y: CGFloat(padding), width: gifWidth, height: gifHeight)
        }
        
        if let animation = animationForGif(gifName: gifName) {
            overlayLayer.add(animation, forKey: "contents")
        }
        
        
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
    
    private func gifToCFData(gifName: String) -> CFData? {
        var name = gifName
        if let dotRange = name.range(of: ".") {
            name.removeSubrange(dotRange.lowerBound..<name.endIndex)
        }
        guard let gifPath = Bundle.main.path(forResource: name, ofType: "GIF") else {
            print("GIF file not found")
            return nil
        }
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: gifPath)) as CFData {
            return data
        }
        return nil
    }
    
    private func animationForGif(gifName: String) -> CAKeyframeAnimation? {
        if gifName.isEmpty { return nil }
        
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.contents))
        var frames: [CGImage] = []
        var delayTimes: [CGFloat] = []
        var totalTime: CGFloat = 0.0
        
        guard let gifData = gifToCFData(gifName: gifName) else {
            return nil
        }
        
        guard let gifSource = CGImageSourceCreateWithData(gifData, nil) else {
            return nil
        }
        
        // get frame
        let frameCount = CGImageSourceGetCount(gifSource)
        
        for i in 0..<frameCount {
            guard let frame = CGImageSourceCreateImageAtIndex(gifSource, i, nil) else { continue }
            guard let dic = CGImageSourceCopyPropertiesAtIndex(gifSource, i, nil) as? [AnyHashable: Any] else { continue }
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
    
    private func exportVideoCompositionToPhotos(videoComposition: AVMutableVideoComposition, outputURL: URL) {
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
    
    private func saveVideoCompositionToPhotosLibrary(videoComposition: AVMutableVideoComposition, outputURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            // Add the video file to the Photos library
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
        }) { [weak self] success, error in
            if success {
                self?.delegate?.exportCompleted()
            } else {
                if let error = error {
                    print("Error saving video to Photos library: \(error.localizedDescription)")
                }
            }
        }
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
