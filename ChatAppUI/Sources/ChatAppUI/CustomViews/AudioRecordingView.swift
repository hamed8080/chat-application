//
//  AudioRecordingView.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import ChatAppViewModels

public struct AudioRecordingView: View {
    @StateObject var viewModel: AudioRecordingViewModel

    public init(viewModel: AudioRecordingViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        let scale = viewModel.isRecording ? 1.8 : 1
        Button {
            // ignore
        } label: {
            Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 24))
                .foregroundColor(viewModel.isRecording ? .chatMeBg.opacity(0.9) : Color.textBlueColor.opacity(0.8))
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    viewModel.toggle()
                }
        )
        .offset(x: viewModel.isRecording ? -10 : 0)
        .scaleEffect(CGSize(width: scale, height: scale))
        .gesture(
            DragGesture(minimumDistance: 100).onEnded { value in
                if value.location.x < 0 {
                    viewModel.toggle()
                }
            }
        )
        .background(RecordAudioBackground(viewModel: viewModel, cornerRadius: 8))
    }
}

struct AudioRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        AudioRecordingView(viewModel: .init(threadViewModel: vm))
            .onAppear {
                vm.setup(thread: MockData.thread)
            }
    }
}
