//
//  MessageRowVideoDownloader.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels
import TalkModels

struct MessageRowVideoDownloader: View {
    let viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }
    private var uploadCompleted: Bool { message.uploadFile == nil || viewModel.uploadViewModel?.state == .completed }

    var body: some View {
        if uploadCompleted, message.isVideo == true, let downloadVM = viewModel.downloadFileVM {
            MessageRowVideoDownloaderContent(viewModel: viewModel)
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

struct MessageRowVideoDownloaderContent: View {
    let viewModel: MessageRowViewModel
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    private var message: Message { viewModel.message }
    var fileName: String? { message.uploadFileName ?? viewModel.fileMetaData?.file?.originalName }

    var body: some View {
        if downloadVM.state == .completed, let fileURL = downloadVM.fileURL {
            VideoPlayerView()
                .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                        ext: viewModel.fileMetaData?.file?.mimeType?.ext,
                                                        title: viewModel.fileMetaData?.name,
                                                        subtitle: viewModel.fileMetaData?.file?.originalName ?? ""))
                .id(fileURL)
        } else {
            VideoDownloadButton()
                .onTapGesture {
                    manageDownload()
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

fileprivate struct VideoDownloadButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageRowVM: MessageRowViewModel
    private var message: Message? { viewModel.message }
    private var percent: Int64 { viewModel.downloadPercent }
    private var stateIcon: String {
        if viewModel.state == .downloading {
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
            .background(Color.App.btnDownload)
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
            .foregroundStyle(Color.App.bgPrimary)
            .fontWeight(.medium)
    }

    @ViewBuilder private var progress: some View {
        if viewModel.state == .downloading {
            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.App.primary)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 42, height: 42)
                .environment(\.layoutDirection, .leftToRight)
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder private var fileNameView: some View {
        if let fileName = message?.fileMetaData?.file?.name ?? message?.uploadFileName {
            Text(fileName)
                .foregroundStyle(Color.App.text)
                .font(.iransansBoldCaption)
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
                .foregroundColor(Color.App.hint)
        }
    }

    @ViewBuilder private var fileSizeView: some View {
        if let fileZize = messageRowVM.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) {
            Text(fileZize.replacingOccurrences(of: "٫", with: "."))
                .multilineTextAlignment(.leading)
                .font(.iransansCaption3)
                .foregroundColor(Color.App.hint)
        }
    }
}

struct MessageRowVideoDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowVideoDownloader(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
