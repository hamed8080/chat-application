//
//  MessageRowFileView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

struct MessageRowFileView: View {
    /// We have to use EnvironmentObject due to we need to update ui after the file has been uploaded so downloadVM now is not a nil value.
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    @State var shareDownloadedFile: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !viewModel.isMe {
                button
            }
            
            VStack(alignment: .leading, spacing: 4) {
                fileNameView
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
        .task {
            viewModel.uploadViewModel?.startUploadFile()
        }
        .sheet(isPresented: $shareDownloadedFile) {
            ActivityViewControllerWrapper(activityItems: [message.tempURL], title: viewModel.fileMetaData?.file?.originalName)
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
        .frame(width: 46, height: 46) /// prevent the button lead to huge resize afetr upload completed.
        .animation(.easeInOut, value: viewModel.isUploadCompleted)
    }

    private func onTapGesture() {
        guard let downloadVM = viewModel.downloadFileVM else { return }
        if downloadVM.state == .completed {
            shareFile()
        } else {
            manageDownload()
        }
    }

    private func shareFile() {
        Task {
            _ = await message.makeTempURL()
            await MainActor.run {
                shareDownloadedFile.toggle()
            }
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

struct MessageRowFileDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowFileView()
            .environmentObject(MessageRowViewModel(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
