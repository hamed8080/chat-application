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
    @EnvironmentObject var audioVM: AVAudioPlayerViewModel
    private var isSameFile: Bool { viewModel.downloadFileVM?.fileURL != nil && audioVM.fileURL?.absoluteString == viewModel.downloadFileVM?.fileURL?.absoluteString }

    var body: some View {
        if message.isAudio {
            HStack(alignment: .top, spacing: 8) {
                if !viewModel.isMe {
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

                if viewModel.isMe {
                    button
                }
            }
            .padding(4)
            .padding(.top, viewModel.paddings.fileViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
            .animation(.easeInOut, value: viewModel.uploadViewModel == nil)
            .animation(.easeInOut, value: viewModel.downloadFileVM == nil)
            .task {
                viewModel.uploadViewModel?.startUploadFile()
            }
            .onTapGesture {
                onTapGesture()
            }
            .task {
                if viewModel.downloadFileVM?.isInCache == true {
                    viewModel.downloadFileVM?.state = .completed
                    viewModel.downloadFileVM?.animateObjectWillChange()
                }
            }
        }
    }

    @ViewBuilder private var audioProgress: some View {
        if message.isAudio == true, viewModel.downloadFileVM?.state == .completed, isSameFile {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: min(audioVM.currentTime / audioVM.duration, 1.0), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(Color.App.textPrimary)
                    .frame(maxWidth: 172)
                Text("\(audioVM.currentTime.timerString(locale: Language.preferredLocale) ?? "") / \(audioVM.duration.timerString(locale: Language.preferredLocale) ?? "")")
                    .foregroundColor(Color.App.textPrimary)
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

    @ViewBuilder private var button: some View {
        ZStack {
            if let downloadVM = viewModel.downloadFileVM {
                DownloadButton()
                    .frame(width: viewModel.isUploadCompleted ? 46 : 0, height: viewModel.isUploadCompleted ? 46 : 0)
                    .environmentObject(downloadVM)
            }
            if let uploadVM = viewModel.uploadViewModel {
                UploadButton()
                    .environmentObject(uploadVM)
            }
        }
        .frame(width: 46, height: 46) /// prevent the button lead to huge resize afetr upload completed.
        .animation(.easeInOut, value: viewModel.isUploadCompleted)
    }

    private func onTapGesture() {
        if viewModel.downloadFileVM?.state == .completed {
            togglePlaying()
        } else {
            manageDownload()
        }
    }

    private func togglePlaying() {
        if let fileURL = viewModel.downloadFileVM?.fileURL {
            try? audioVM.setup(message: message,
                               fileURL: fileURL,
                               ext: viewModel.fileMetaData?.file?.mimeType?.ext,
                               title: viewModel.fileMetaData?.file?.originalName ?? viewModel.fileMetaData?.name ?? "",
                               subtitle: viewModel.fileMetaData?.file?.originalName ?? "")
            audioVM.toggle()
        }
    }

    private func manageDownload() {
        if let downloadVM = viewModel.downloadFileVM {
            if downloadVM.state == .paused {
                downloadVM.resumeDownload()
            } else if downloadVM.state == .downloading {
                downloadVM.pauseDownload()
            } else {
                downloadVM.startDownload()
            }
        }
    }
}

struct MessageRowAudioDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowAudioView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
