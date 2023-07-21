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
    var timer: Timer?
    @Published public var timerString = "00:00"

    public init(fileURL: URL, ext: String? = nil, title: String? = nil, subtitle: String? = nil, directLink: Bool = false) {
        self.fileURL = fileURL
        self.ext = ext
        self.title = title
        self.subtitle = subtitle
        super.init()
        do {
            var url: URL
            if !directLink {
                let hardLinkURL = fileURL.appendingPathExtension(ext ?? "mp4")
                if !FileManager.default.fileExists(atPath: hardLinkURL.path()) {
                    try FileManager.default.linkItem(at: fileURL, to: hardLinkURL)
                }
                url = hardLinkURL
            } else {
                url = fileURL
            }
            let asset = AVURLAsset(url: url)
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

    public func toggle() {
        if player?.timeControlStatus == .paused {
            player?.play()
            startTimer()
        } else {
            player?.pause()
            stopTimer()
        }
    }

    public func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let elapsed = self?.player?.currentTime() else { return }
            self?.timerString = elapsed.seconds.rounded().timerString ?? "00:00"
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }
}
