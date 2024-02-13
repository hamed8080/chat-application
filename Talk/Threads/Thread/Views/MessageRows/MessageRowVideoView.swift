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
        if message.isVideo {
            HStack(alignment: .top, spacing: viewModel.isDownloadCompleted ? 0 : 8) {
                if !viewModel.isMe {
                    button
                }

                playerContainerView

                if viewModel.isMe {
                    button
                }
            }
            .padding(viewModel.isDownloadCompleted ? 0 : 4)
            .padding(.top, viewModel.isDownloadCompleted ? 0 : viewModel.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
            .animation(.easeInOut, value: viewModel.uploadViewModel == nil)
            .animation(.easeInOut, value: viewModel.downloadFileVM == nil)
            .task {
                viewModel.uploadViewModel?.startUploadFile()
                if viewModel.downloadFileVM?.isInCache == true {
                    viewModel.downloadFileVM?.state = .completed
                    viewModel.downloadFileVM?.animateObjectWillChange()
                }
            }
        }
    }

    @ViewBuilder private var fileNameView: some View {
        if let fileName = viewModel.fileName {
            Text(fileName)
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldCaption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder private var fileTypeView: some View {
        if let extName = viewModel.extName {
            Text(extName)
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var fileSizeView: some View {
        if let fileZize = viewModel.computedFileSize {
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
        if viewModel.isDownloadCompleted, let fileURL = viewModel.downloadFileVM?.fileURL {
            VideoPlayerView()
                .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                        ext: viewModel.fileMetaData?.file?.mimeType?.ext,
                                                        title: viewModel.fileMetaData?.name,
                                                        subtitle: viewModel.fileMetaData?.file?.originalName ?? ""))
                .id(fileURL)
        }
    }

    @ViewBuilder private var button: some View {
        ZStack {
            if let downloadVM = viewModel.downloadFileVM, downloadVM.state != .completed {
                DownloadButton() {
                    onTapGesture()
                }
                .frame(width: viewModel.isUploadCompleted ? 46 : 0, height: viewModel.isUploadCompleted ? 46 : 0)
                .environmentObject(downloadVM)
            }
            if let uploadVM = viewModel.uploadViewModel {
                UploadButton()
                    .environmentObject(uploadVM)
            }
        }
        .frame(width: viewModel.isDownloadCompleted ? 0 : 46, height: viewModel.isDownloadCompleted ? 0 : 46) /// prevent the button lead to huge resize afetr upload completed.
        .animation(.easeInOut, value: viewModel.isUploadCompleted)
    }

    private func onTapGesture() {
        if viewModel.downloadFileVM?.state != .completed {
            manageDownload()
        }
    }

    private func manageDownload() {
        guard let downloadVM = viewModel.downloadFileVM else { return }
        if downloadVM.state == .paused {
            downloadVM.resumeDownload()
        } else if downloadVM.state == .downloading {
            downloadVM.pauseDownload()
        } else {
            downloadVM.startDownload()
        }
    }
}

struct MessageRowVideoDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowVideoView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
