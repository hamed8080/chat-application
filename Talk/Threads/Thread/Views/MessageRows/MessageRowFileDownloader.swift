//
//  MessageRowAudioDownloader.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

struct MessageRowFileDownloader: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var uploadCompleted: Bool { message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed }
    private var isFileView: Bool { uploadCompleted && message.isFileType && !viewModel.isMapType && !message.isImage && !message.isAudio && !message.isVideo }

    var body: some View {
        if isFileView, let downloadVM = viewModel.downloadFileVM {
            MessageRowFileDownloaderContent()
                .environmentObject(downloadVM)
                .task {
                    if downloadVM.isInCache {
                        downloadVM.state = .completed
                        viewModel.animateObjectWillChange()
                    }
                }
        }
    }
}

struct MessageRowFileDownloaderContent: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    private var message: Message { viewModel.message }
    @State var shareDownloadedFile: Bool = false

    var body: some View {
        HStack {
            FileDownloadButton()
        }
        .environmentObject(downloadVM)
        .sheet(isPresented: $shareDownloadedFile) {
            ActivityViewControllerWrapper(activityItems: [message.tempURL], title: viewModel.fileMetaData?.file?.originalName)
        }
        .onTapGesture {
            if downloadVM.state == .completed {
                shareFile()
            } else {
                manageDownload()
            }
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
        if downloadVM.state == .paused {
            downloadVM.resumeDownload()
        } else if downloadVM.state == .downloading {
            downloadVM.pauseDownload()
        } else {
            downloadVM.startDownload()
        }
    }
}

fileprivate struct FileDownloadButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    @Environment(\.colorScheme) var scheme
    private var message: Message? { viewModel.message }
    private var percent: Int64 { viewModel.downloadPercent }
    private var stateIcon: String {
        if let iconName = message?.iconName, viewModel.state == .completed {
            return iconName
        } else if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                iconView
                progress
            }
            .frame(width: 46, height: 46)
            .background(scheme == .light ? Color.App.accent : Color.App.white)
            .clipShape(RoundedRectangle(cornerRadius:(46 / 2)))

            VStack(alignment: .leading, spacing: 4) {
                fileNameView
                HStack {
                    fileTypeView
                    fileSizeView
                }
            }
        }
        .padding(4)
    }

    @ViewBuilder private var iconView: some View {
        Image(systemName: stateIcon.replacingOccurrences(of: ".circle", with: ""))
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.black)
            .fontWeight(.medium)
    }

    @ViewBuilder private var progress: some View {
        if viewModel.state == .downloading {
            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.App.accent)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 42, height: 42)
                .environment(\.layoutDirection, .leftToRight)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder private var fileNameView: some View {
        if let fileName = message?.fileMetaData?.file?.name ?? message?.uploadFileName {
            Text(fileName)
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldCaption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder private var fileTypeView: some View {
        let split = messageRowVM.fileMetaData?.file?.originalName?.split(separator: ".")
        let ext = messageRowVM.fileMetaData?.file?.extension
        let lastSplit = String(split?.last ?? "")
        let extensionName = (ext ?? lastSplit)
        if !extensionName.isEmpty {
            Text(extensionName.uppercased())
                .multilineTextAlignment(.leading)
                .font(.iransansBoldCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }

    @ViewBuilder private var fileSizeView: some View {
        if let fileZize = messageRowVM.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) {
            Text(fileZize.replacingOccurrences(of: "٫", with: "."))
                .multilineTextAlignment(.leading)
                .font(.iransansCaption3)
                .foregroundColor(Color.App.textPrimary.opacity(0.7))
        }
    }
}

struct MessageRowFileDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowFileDownloader(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
