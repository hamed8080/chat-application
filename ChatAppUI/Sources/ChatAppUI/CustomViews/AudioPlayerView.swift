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
        VStack(spacing: 0) {
            if !audioPlayerVM.isClosed {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            audioPlayerVM.toggle()
                        } label: {
                            Label("", systemImage: audioPlayerVM.isPlaying ? "pause.circle" : "play.circle")
                                .font(.title2.weight(.thin))
                        }
                        VStack(alignment: .leading) {
                            Text(verbatim: audioPlayerVM.title)
                                .font(.subheadline)
                            Text(verbatim: audioPlayerVM.subtitle)
                                .font(.caption2.weight(.light))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text(verbatim: audioPlayerVM.currentTime.timerString ?? "")
                            .foregroundColor(.gray)
                            .animation(.none)
                        Button {
                            audioPlayerVM.close()
                        } label: {
                            Label("", systemImage: "xmark.circle")
                        }
                    }
                    .padding([.leading, .trailing], 12)
                    Spacer()
                    ProgressView(value: min(audioPlayerVM.currentTime / audioPlayerVM.duration, 1.0) , total: 1.0)
                        .progressViewStyle(.linear)
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                }
                .transition(.asymmetric(insertion: .push(from: .top), removal: .push(from: .bottom)))
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 48)
                .background(
                    VStack {
                        Rectangle()
                            .fill(Color.clear)
                            .background(.ultraThinMaterial)
                    }
                )
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
