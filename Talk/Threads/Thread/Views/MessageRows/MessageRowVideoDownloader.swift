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
        }
    }
}

struct MessageRowVideoDownloaderContent: View {
    let viewModel: MessageRowViewModel
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    private var message: Message { viewModel.message }
    var fileName: String? { message.fileName ?? message.fileMetaData?.file?.originalName }

    var body: some View {
        if downloadVM.state == .completed, let fileURL = downloadVM.fileURL {
            VStack {
                VideoPlayerView()
                    .frame(maxWidth: ThreadViewModel.maxAllowedWidth, maxHeight: 320)
                    .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                            ext: message.fileMetaData?.file?.mimeType?.ext,
                                                            title: message.fileMetaData?.name,
                                                            subtitle: message.fileMetaData?.file?.originalName ?? ""))
                    .id(fileURL)
            }
        }

        if downloadVM.state != .completed {
            HStack(spacing: 4) {
                VideoDownloadButton(message: viewModel.message, config: .normal)
                    .environmentObject(downloadVM)
                fileNameTextView
            }
        }
    }

    @ViewBuilder var fileNameTextView: some View {
        if let fileName {
            Text("\(fileName)\(message.fileExtension ?? "")")
                .foregroundStyle(Color.App.text)
                .font(.iransansBoldCaption)
        }
    }
}

fileprivate struct VideoDownloadButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    let message: Message?
    var percent: Int64 { viewModel.downloadPercent }
    let config: DownloadFileViewConfig
    var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: stateIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(config.iconColor)

                Circle()
                    .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(config.progressColor)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: config.circleProgressMaxWidth, height: config.circleProgressMaxWidth)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: config.iconWidth, height: config.iconHeight)
            .background(config.iconCircleColor)
            .clipShape(RoundedRectangle(cornerRadius:(config.iconHeight / 2)))
            .onTapGesture {
                if viewModel.state == .paused {
                    viewModel.resumeDownload()
                } else if viewModel.state == .downloading {
                    viewModel.pauseDownload()
                } else {
                    viewModel.startDownload()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let fileName = message?.fileName, config.showTrailingFileName {
                    Text(fileName)
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldSubheadline)
                        .foregroundColor(.white)
                }

                if let fileZize = message?.fileMetaData?.file?.size, config.showFileSize {
                    Text(String(fileZize))
                        .multilineTextAlignment(.leading)
                        .font(.iransansBoldCaption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct MessageRowVideoDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowVideoDownloader(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
