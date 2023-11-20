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
    @State var opacity: Double = 0
    @Binding var isRecording: Bool

    public init(isRecording: Binding<Bool>) {
        _isRecording = isRecording
    }

    public var body: some View {
        if viewModel.isRecording {
            HStack(spacing: 0) {
                Button {
                    viewModel.stopAndAddToAttachments()
                    isRecording = false
                } label: {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.App.pink.opacity(opacity), Color.App.primary, Color.App.primary)
                        .animation(.easeInOut(duration: 0.8), value: opacity)
                        .onAppear {
                            opacity = opacity == 1  ? 0 : 1
                        }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
                .buttonStyle(.borderless)
                .fontWeight(.light)

                Text(viewModel.timerString)
                    .font(.iransansBody)
                    .offset(x: 8)
                    .animation(.easeInOut, value: viewModel.timerString)

                Spacer()

                Button {
                    viewModel.isRecording = false
                    viewModel.stop()
                    isRecording = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.App.white, Color.App.primary)
                        .frame(width: 26, height: 26)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
                .buttonStyle(.borderless)
                .fontWeight(.light)
            }
            .animation(.easeInOut, value: viewModel.isRecording)
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
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
        AudioRecordingView(isRecording: .constant(false))
            .environmentObject(viewModel)
    }
}
