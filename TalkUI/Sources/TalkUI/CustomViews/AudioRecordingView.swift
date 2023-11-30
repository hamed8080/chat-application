//
//  AudioRecordingView.swift
//  TalkUI
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import TalkViewModels
import ChatModels

public struct AudioRecordingView: View {
    @EnvironmentObject var viewModel: AudioRecordingViewModel
    public init() {}

    public var body: some View {
        ZStack {
            if viewModel.isRecording {
                InVoiceRecordingView()
            } else {
                VoiceRecoderSenderView()
            }
        }
        .animation(.easeInOut, value: viewModel.isRecording)
    }
}

struct VoiceRecoderSenderView: View {
    @EnvironmentObject var viewModel: AudioRecordingViewModel
    @EnvironmentObject var audioPlayerVM: AVAudioPlayerViewModel

    var body: some View {
        HStack(spacing: 0){
            Button {
                withAnimation {
                    viewModel.threadViewModel?.sendAudiorecording()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, Color.App.primary)
            }
            .frame(width: 48, height: 48)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.return, modifiers: [.command])

            Spacer()
            HStack(spacing: 4) {
                Text(viewModel.timerString)
                    .foregroundStyle(Color.App.text)
                    .font(.iransansCaption2)

                Image("waveform")
                    .resizable()
                    .scaledToFit()

                Button {
                    withAnimation {
                        audioPlayerVM.toggle()
                    }
                } label: {
                    Image(systemName: audioPlayerVM.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.App.text)
                        .fontWeight(.light)
                }
                .frame(width: 28, height: 28)
                .buttonStyle(.borderless)
                .keyboardShortcut(.return, modifiers: [.command])
            }
            .frame(height: 28)
            .padding(.horizontal, 12)
            .background(Color.App.primary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Spacer()
            Button {
                withAnimation {
                    viewModel.cancel()
                    audioPlayerVM.close()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.text)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderless)
            .frame(width: 48, height: 48)
        }
    }
}

struct InVoiceRecordingView: View {
    @EnvironmentObject var viewModel: AudioRecordingViewModel
    @State var opacity: Double = 0
    @State var scale: CGFloat = 0.5

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.App.primary.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .scaleEffect(x: scale, y: scale, anchor: .center)
                    .contentShape(Rectangle())
                    .allowsTightening(false)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 0.8, damping: 0.8, initialVelocity: 3)) {
                                scale = scale == 1 ? 0.5 : 1
                            }
                        }
                    }

                Button {
                    viewModel.stop()
                    if let fileURL = viewModel.recordingOutputPath {
                        AppState.shared.objectsContainer.audioPlayerVM.setup(fileURL: fileURL,
                                                                             ext: fileURL.fileExtension,
                                                                             title: fileURL.fileName,
                                                                             subtitle: "")
                    }
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.App.text)
                        .fontWeight(.semibold)
                        .contentShape(Rectangle())
                }
                .frame(width: 48, height: 48)
                .background(Color.App.primary)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            }

            Text("Thread.isVoiceRecording")
                .foregroundStyle(Color.App.hint)
                .font(.iransansCaption)
                .padding(.leading)

            Spacer()

            Text(viewModel.timerString)
                .font(.iransansBody)
                .animation(.easeInOut, value: viewModel.timerString)
                .padding(.trailing)

            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.App.red.opacity(opacity))
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                        withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 0.8, damping: 0.8, initialVelocity: 3)) {
                            opacity = opacity == 1 ? 0 : 1
                        }
                    }
                }
        }
        .animation(.easeInOut, value: viewModel.isRecording)
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
}

struct AudioRecordingView_Previews: PreviewProvider {
    @Namespace static var id
    static var threadVM = ThreadViewModel(thread: MockData.thread)
    static var viewModel: AudioRecordingViewModel {
        let viewModel = AudioRecordingViewModel()
        viewModel.threadViewModel = threadVM
        return viewModel
    }

    static var previews: some View {
        AudioRecordingView()
            .environmentObject(viewModel)
    }
}
