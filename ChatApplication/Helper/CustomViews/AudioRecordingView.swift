//
//  AudioRecordingView.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import SwiftUI

struct AudioRecordingView: View {
    @ObservedObject var viewModel: AudioRecordingViewModel

    var body: some View {
        let scale = viewModel.isRecording ? 1.8 : 1
        Button {
            // ignore
        } label: {
            Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                .font(.system(size: 24))
                .foregroundColor(viewModel.isRecording ? Color(named: "chat_me").opacity(0.9) : Color.gray)
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
