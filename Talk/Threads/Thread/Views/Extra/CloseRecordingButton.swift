//
//  MoveToBottomButton.swift
//  Talk
//
//  Created by hamed on 7/7/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct CloseRecordingButton: View {
    @EnvironmentObject var viewModel: AudioRecordingViewModel
    @EnvironmentObject var scrollVM: ThreadScrollingViewModel

    var body: some View {
        if viewModel.isRecording {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        scrollVM.disableExcessiveLoading()
                        viewModel.cancel()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: viewModel.isRecording ? 12 : 0, height: viewModel.isRecording ? 12 : 0)
                        .padding()
                        .foregroundStyle(Color.App.textPrimary)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                        .fontWeight(.semibold)
                }
                .frame(width: viewModel.isRecording ? 40 : 0, height: viewModel.isRecording ? 40 : 0)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(20)))
                .shadow(color: .gray.opacity(0.4), radius: 2)
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(EdgeInsets(top: 0, leading: viewModel.isRecording ? 20 : 8, bottom: 8, trailing: 0))
        }
    }
}
