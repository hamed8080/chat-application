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
    let id: Namespace.ID

    public init(isRecording: Binding<Bool>, nameSpace: Namespace.ID) {
        _isRecording = isRecording
        id = nameSpace
    }

    public var body: some View {
        if viewModel.isRecording {
            HStack(spacing: 0) {

                Button {
                    viewModel.isRecording = false
                    viewModel.stop()
                    isRecording = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.main)
                        .frame(width: 26, height: 26)
                }
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .buttonStyle(.borderless)
                .fontWeight(.light)
                .matchedGeometryEffect(id: "PAPERCLIPS", in: id)

                Text(viewModel.timerString)
                    .font(.iransansBody)
                    .offset(x: 8)
                    .animation(.easeInOut, value: viewModel.timerString)

                Spacer()
                Image(systemName: "record.circle")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.pink.opacity(opacity), Color.main, Color.main)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: opacity)
                    .onAppear {
                        opacity = opacity == 1  ? 0 : 1
                    }
            }
            .animation(.easeInOut, value: viewModel.isRecording)
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .padding([.top, .bottom], 8)
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
        AudioRecordingView(isRecording: .constant(false), nameSpace: AudioRecordingView_Previews.id)
            .environmentObject(viewModel)
    }
}
