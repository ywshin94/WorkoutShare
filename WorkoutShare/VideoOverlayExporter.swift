// VideoOverlayExporter.swift — UIImage snapshot 받는 구조로 수정

import AVFoundation
import UIKit
import Photos

class VideoOverlayExporter {
    static func overlayImage(on videoURL: URL, with overlayImage: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(false, NSError(domain: "No video track found", code: -1, userInfo: nil))
            return
        }

        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(false, NSError(domain: "Failed to add track", code: -1, userInfo: nil))
            return
        }

        do {
            try compositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        } catch {
            completion(false, error)
            return
        }

        let videoSize = videoTrack.naturalSize

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let overlayLayer = CALayer()
        overlayLayer.contents = overlayImage.cgImage
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        overlayLayer.contentsGravity = .resizeAspectFill
        overlayLayer.masksToBounds = true

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.mov")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(false, NSError(domain: "Exporter creation failed", code: -1, userInfo: nil))
            return
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.videoComposition = videoComposition

        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                }) { success, error in
                    DispatchQueue.main.async {
                        completion(success, error)
                    }
                }
            case .failed, .cancelled:
                DispatchQueue.main.async {
                    completion(false, exporter.error)
                }
            default:
                break
            }
        }
    }
}

