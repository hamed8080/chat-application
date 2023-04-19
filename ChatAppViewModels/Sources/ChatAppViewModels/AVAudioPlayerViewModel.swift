import Combine
import Foundation
import AVFoundation

public final class AVAudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isPlaying: Bool = false
    @Published public var player: AVAudioPlayer?
    public var fileURL: URL
    public var ext: String?

    public init(fileURL: URL, ext: String?) {
        self.fileURL = Bundle.main.url(forResource: "Tamasha", withExtension: "mp3") ?? fileURL
        self.ext = ext
    }

    public func setup() {
        if player != nil { return }
        do {
            let audioData = try Data(contentsOf: fileURL, options: NSData.ReadingOptions.mappedIfSafe)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            player = try AVAudioPlayer(data: audioData, fileTypeHint: ext)
            player?.delegate = self
        } catch let error as NSError {
            print(error.description)
        }
    }

    public func toggle() {
        isPlaying.toggle()
        try? AVAudioSession.sharedInstance().setActive(isPlaying)
        if isPlaying {
            player?.prepareToPlay()
            player?.play()
        } else {
            player?.pause()
        }
    }

    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        isPlaying = false
    }
}
