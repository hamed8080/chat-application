//
//  MessageRowAudioView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

struct MessageRowAudioView: View {
    /// We have to use EnvironmentObject due to we need to update ui after the audio has been uploaded so downloadVM now is not a nil value.
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !viewModel.calMessage.isMe {
                button
            }

            VStack(alignment: .leading, spacing: 4) {
                fileNameView
                audioProgress
                HStack {
                    fileTypeView
                    fileSizeView
                }
            }

            if viewModel.calMessage.isMe {
                button
            }
        }
        .padding(4)
        .padding(.top, viewModel.calMessage.sizes.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
    }

    @ViewBuilder private var audioProgress: some View {
        VStack(alignment: .leading, spacing: 1) {
            let timerString = viewModel.audioTimerString
            ProgressView(value: viewModel.fileState.progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(Color.App.textPrimary)
                .frame(maxWidth: 172)
            Text(timerString)
                .foregroundColor(Color.App.textPrimary)
                .frame(minHeight: 10)
        }
    }

    @ViewBuilder private var fileNameView: some View {
        if let fileName = viewModel.calMessage.fileName {
            Text(fileName)
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldCaption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder private var fileTypeView: some View {
        if let extName = viewModel.calMessage.extName {
            Text(extName)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var fileSizeView: some View {
        if let fileZize = viewModel.calMessage.computedFileSize {
            Text(fileZize)
                .multilineTextAlignment(.leading)
                .font(.iransansCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var button: some View {
        ZStack {
            DownloadButton() {
                onTapGesture()
            }
            .frame(width: !viewModel.fileState.isUploading ? 46 : 0, height: !viewModel.fileState.isUploading ? 46 : 0)
            if viewModel.fileState.isUploading {
                UploadButton()
            }
        }
        .frame(width: 46, height: 46) /// prevent the button lead to huge resize afetr upload completed.
        .animation(.easeInOut, value: viewModel.fileState.isUploading)
    }

    private func onTapGesture() {
        viewModel.onTap()
    }
}

struct MessageRowAudioDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowAudioView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
