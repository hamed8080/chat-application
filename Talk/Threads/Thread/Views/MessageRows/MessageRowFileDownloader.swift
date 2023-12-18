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
    private var isFileView: Bool { uploadCompleted && message.isFileType && !message.isMapType && !message.isImage && !message.isAudio && !message.isVideo }

    var body: some View {
        if isFileView, let downloadVM = viewModel.downloadFileVM {
            MessageRowFileDownloaderContent(viewModel: viewModel)
                .environmentObject(downloadVM)
        }
    }
}

struct MessageRowFileDownloaderContent: View {
    let viewModel: MessageRowViewModel
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    private var message: Message { viewModel.message }
    var fileName: String? { message.fileName ?? message.fileMetaData?.file?.originalName }
    @State var shareDownloadedFile: Bool = false
    private let config = DownloadFileViewConfig.normal

    var body: some View {
        if downloadVM.state == .completed {
            HStack {
                if let iconName = message.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .foregroundStyle(config.iconColor, config.iconCircleColor)
                        .scaledToFit()
                        .frame(width: config.iconWidth, height: config.iconHeight)
                }
                VStack(alignment: .leading, spacing: 4) {
                    fileNameTextView
                }
            }
            .sheet(isPresented: $shareDownloadedFile) {
                ActivityViewControllerWrapper(activityItems: [message.tempURL], title: message.fileMetaData?.file?.originalName)
            }
            .onTapGesture {
                Task {
                    _ = await message.makeTempURL()
                    await MainActor.run {
                        shareDownloadedFile.toggle()
                    }
                }
            }
        }

        if downloadVM.state != .completed {
            HStack(spacing: 4) {
                FileDownloadButton(message: viewModel.message, config: .normal)
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

fileprivate struct FileDownloadButton: View {
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

struct MessageRowFileDownloader_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowFileDownloader(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
    }
}
