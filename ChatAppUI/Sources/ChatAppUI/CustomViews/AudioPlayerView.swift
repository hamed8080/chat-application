//
//  AudioPlayerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI
import ChatAppViewModels

public struct AudioPlayerView: View {
    @EnvironmentObject var audioPlayerVM: AVAudioPlayerViewModel
    public init(){}

    public var body: some View {
        if audioPlayerVM.isPlaying {
            VStack {
                HStack {
                    Text(verbatim: audioPlayerVM.title)
                    Button {
                        audioPlayerVM.pause()
                    } label: {
                        Label("play", systemImage: "play")
                    }
                }
            }
        }
    }
}

struct AudioPlayerPreview: PreviewProvider {
    private static var audioPlayerVm = AVAudioPlayerViewModel()
    static var previews: some View {
        AudioPlayerView()
            .environmentObject(audioPlayerVm)
            .onAppear {
                if let fileURL = Bundle.main.url(forResource: "new_message", withExtension: "mp3") {
                    audioPlayerVm.setup(fileURL: fileURL, ext: "mp3", title: "Note")
                }
            }
    }
}
