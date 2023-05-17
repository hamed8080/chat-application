import Combine
import Foundation
import AVFoundation

public final class AVAudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isPlaying: Bool = false
    @Published public var player: AVAudioPlayer?
    public var title: String = ""
    public override init() {}

    public func setup(fileURL: URL, ext: String?, category: AVAudioSession.Category = .playback, title: String? = nil) {
        self.title = title ?? fileURL.lastPathComponent
        if player != nil { return }
        do {
            let audioData = try Data(contentsOf: fileURL, options: NSData.ReadingOptions.mappedIfSafe)
            try AVAudioSession.sharedInstance().setCategory(category)
            player = try AVAudioPlayer(data: audioData, fileTypeHint: ext)
            player?.delegate = self
        } catch let error as NSError {
            print(error.description)
        }
    }

    public func play() {
        isPlaying = true
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.prepareToPlay()
        player?.play()
    }

    public func pause() {
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false)
        player?.pause()
    }

    public func toggle() {
        if !isPlaying {
            play()
        } else {
            pause()
        }
    }

    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        isPlaying = false
    }
}
