//
//  AudioPlayerView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI
import TalkViewModels

public struct AudioPlayerView: View {
    @EnvironmentObject var audioPlayerVM: AVAudioPlayerViewModel
    public init(){}

    public var body: some View {
        VStack(spacing: 0) {
            if !audioPlayerVM.isClosed {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            audioPlayerVM.toggle()
                        } label: {
                            Image(systemName: audioPlayerVM.isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(13)
                                .foregroundStyle(Color.App.primary)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 36, height: 48)

                        HStack {
                            Text(verbatim: audioPlayerVM.title)
                                .font(.iransansSubheadline)
                            Text(verbatim: audioPlayerVM.subtitle)
                                .font(.iransansCaption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        Spacer()
                        Text(verbatim: audioPlayerVM.currentTime.timerString ?? "")
                            .foregroundColor(.gray)
                            .animation(.none)
                            .font(.iransansCaption2)
                        Button {
                            audioPlayerVM.close()
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(Color.App.hint)
                                .padding(12)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 36, height: 36)
                    }
                    .frame(height: 48)
                    ProgressView(value: min(audioPlayerVM.currentTime / audioPlayerVM.duration, 1.0),
                                 total: 1.0)
                        .progressViewStyle(.linear)
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                        .tint(Color.App.primary)
                }
                .transition(.asymmetric(insertion: .push(from: .top), removal: .push(from: .bottom)))
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(MixMaterialBackground())
            }
        }
        .animation(.easeInOut(duration: 0.15), value: audioPlayerVM.isPlaying)
        .animation(.easeInOut(duration: 0.15), value: audioPlayerVM.isClosed)
        .animation(.easeInOut, value: audioPlayerVM.currentTime)
      }
}

struct AudioPlayerPreview: PreviewProvider {
    struct Preview: View {
        @ObservedObject var audioPlayerVm = AVAudioPlayerViewModel()

        var body: some View {
            AudioPlayerView()
                .environmentObject(audioPlayerVm)
                .onAppear {
                    audioPlayerVm.setup(fileURL: URL(string: "https://www.google.com")!, ext: "mp3", title: "Note", subtitle: "Test")
                    audioPlayerVm.isClosed = false
                }
        }
    }

    static var previews: some View {
        Preview()
    }
}
