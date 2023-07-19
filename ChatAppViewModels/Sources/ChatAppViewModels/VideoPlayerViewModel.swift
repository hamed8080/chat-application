//
//  VideoPlayerViewModel.swift
//  ChatApplication
//
//  Created by hamed on 3/16/23.
//

import UIKit
import Combine
import Foundation
import AVKit

public class VideoPlayerViewModel: NSObject, ObservableObject, AVAssetResourceLoaderDelegate {
    @Published public var player: AVPlayer?
    let fileURL: URL
    let ext: String?
    var title: String?
    var subtitle: String?

    public init(fileURL: URL, ext: String? = nil, title: String? = nil, subtitle: String? = nil) {
        self.fileURL = fileURL
        self.ext = ext
        self.title = title
        self.subtitle = subtitle
        super.init()
        do {
            let hardLinkURL = fileURL.appendingPathExtension(ext ?? "mp4")
            if !FileManager.default.fileExists(atPath: hardLinkURL.path()) {
                try FileManager.default.linkItem(at: fileURL, to: hardLinkURL)
            }
            let asset = AVURLAsset(url: hardLinkURL)
            asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
            let item = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: item)
            item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        } catch {
            print("error in hardlinking: \(error.localizedDescription)")
        }
    }

    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem else { return }
        switch item.status {

        case .unknown:
            print("unkown state video player")
        case .readyToPlay:
            print("reday video player")
        case .failed:
            guard let error = item.error else { return }
            print(error)
            print("failed state video player\(error.localizedDescription)")
        @unknown default:
            print("default status video player")
        }
    }

    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }
}
