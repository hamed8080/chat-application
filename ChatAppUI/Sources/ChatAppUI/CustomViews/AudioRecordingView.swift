//
//  AudioRecordingView.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import ChatAppViewModels

public struct AudioRecordingView: View {
    @EnvironmentObject var viewModel: AudioRecordingViewModel
    @State var opacity: Double = 0

    public init() {}

    public var body: some View {
        if viewModel.isRecording {
            HStack(spacing: 0) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.blue)
                    .onTapGesture {
                        viewModel.isRecording = false
                        viewModel.stop()
                    }
                Text(viewModel.timerString)
                    .font(.iransansBody)
                    .offset(x: 8)
                    .animation(.easeInOut, value: viewModel.timerString)

                Spacer()
                Image(systemName: "record.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(.pink.opacity(opacity), .blue, .blue)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: opacity)
                    .onAppear {
                        opacity = 1
                    }
            }
            .animation(.easeInOut, value: viewModel.isRecording)
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .padding([.top, .bottom], 8)
        }
    }
}

struct AudioRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        AudioRecordingView()
            .environmentObject(AudioRecordingViewModel(threadViewModel: ThreadViewModel()))
            .onAppear {
                vm.setup(thread: MockData.thread)
            }
    }
}
