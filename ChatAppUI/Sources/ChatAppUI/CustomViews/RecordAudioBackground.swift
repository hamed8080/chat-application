//
//  RecordAudioBackground.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/1/21.
//

import SwiftUI
import ChatAppViewModels

public struct RecordAudioBackground: View {
    @StateObject var viewModel: AudioRecordingViewModel
    @State var degrees: [CGFloat] = [270, 40, 70, 90, 120, 160, 220, 260, 290, 360]
    var scale: CGFloat = 6
    var cornerRadius: CGFloat = 24
    var blurRadius = 1

    public var body: some View {
        if viewModel.isRecording {
            ZStack {
                ForEach(1 ... 10, id: \.self) { item in
                    createRectangle(index: item - 1)
                }
            }
            .animation(
                .easeInOut(duration: 0.5)
                    .speed(0.099)
                    .repeatForever(autoreverses: true)
                    .delay(0.0),
                value: 0
            )
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    withAnimation {
                        degrees.enumerated().forEach { element in
                            degrees[element.offset] = element.element + (element.element * 80 / 100)
                        }
                    }
                }
            }
        } else {
            Circle()
                .scale()
                .foregroundColor(Color.clear)
        }
    }

    @ViewBuilder
    func createRectangle(index: Int) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .scale(x: scale, y: scale)
            .rotation(Angle(degrees: degrees[index]))
            .foregroundColor(.textBlueColor.opacity(Double(index) * 80 / 100))
            .blur(radius: CGFloat(index) * 80 / 100)
    }
}

struct RecordAudioBackground_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel()
        let vm = AudioRecordingViewModel(threadViewModel: threadVM)
        RecordAudioBackground(viewModel: vm, scale: 2)
            .frame(width: 128, height: 128)
            .onAppear {
                threadVM.setup(thread: MockData.thread)
                vm.toggle()
            }
    }
}
