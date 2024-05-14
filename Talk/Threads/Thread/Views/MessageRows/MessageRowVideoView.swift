//
//  MessageRowVideoView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

struct MessageRowVideoView: View {
    /// We have to use EnvironmentObject due to we need to update ui after the video has been uploaded so downloadVM now is not a nil value.
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        HStack(alignment: .top, spacing: viewModel.fileState.state == .completed ? 0 : 8) {
            if !viewModel.calMessage.isMe {
                button
            }

            playerContainerView

            if viewModel.calMessage.isMe {
                button
            }
        }
        .padding(viewModel.fileState.state == .completed ? 0 : 4)
        .padding(.top, viewModel.fileState.state == .completed ? 0 : viewModel.calMessage.sizes.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        .animation(.easeInOut, value: viewModel.fileState.isUploading)
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

    @ViewBuilder private var playerContainerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            playerView
            fileNameView
            HStack {
                fileTypeView
                fileSizeView
            }
        }
    }

    @ViewBuilder private var playerView: some View {
        if viewModel.fileState.state == .completed, let fileURL = viewModel.fileState.url {
            let mtd = viewModel.calMessage.fileMetaData
            VideoPlayerView()
                .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                        ext: mtd?.file?.mimeType?.ext,
                                                        title: mtd?.name,
                                                        subtitle: mtd?.file?.originalName ?? ""))
                .id(fileURL)
        }
    }

    @ViewBuilder private var button: some View {
        ZStack {
            if viewModel.fileState.state != .completed && !viewModel.fileState.isUploading {
                DownloadButton() {
                    viewModel.onTap()
                }
            }

            if viewModel.fileState.isUploading {
                UploadButton()
            }
        }
        .frame(width: viewModel.fileState.state == .completed ? 0 : 46, height: viewModel.fileState.state == .completed ? 0 : 46) /// prevent the button lead to huge resize afetr upload completed.
        .animation(.easeInOut, value: viewModel.fileState.isUploading)
    }
}

struct MessageRowVideoDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowVideoView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
