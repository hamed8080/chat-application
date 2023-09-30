//
//  FileView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatDTO
import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct VideoView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        MessageListVideoView()
            .environmentObject(viewModel)
    }
}

struct MessageListVideoView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            VideoRowView(message: message)
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.leading)
                    }
                }
                .onAppear {
                    if message == viewModel.messages.last {
                        viewModel.loadMore()
                    }
                }
        }
        if viewModel.isLoading {
            LoadingView()
        }
    }
}

struct VideoRowView: View {
    let message: Message
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(message.fileMetaData?.name ?? message.messageTitle)
                    .font(.iransansBody)
                Text(message.fileMetaData?.file?.size?.toSizeString ?? "")
                    .foregroundColor(.secondaryLabel)
                    .font(.iransansCaption2)
            }
            Spacer()

            let view = DownloadVideoButtonView(threadVM: threadVM)
                .padding(4)
            if let downloadVM = threadVM.messageViewModel(for: message).downloadFileVM {
                view.environmentObject(downloadVM)
            } else {
                view
            }
        }
        .padding([.leading, .trailing])
        .onTapGesture {
            threadVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }
    }
}

struct DownloadVideoButtonView: View {
    let threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private var message: Message? { viewModel.message }
    static var config: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = .green
        config.iconColor = .orange
        return config
    }()

    var body: some View {
        switch viewModel.state {
        case .COMPLETED:
            if message?.isVideo == true, let fileURL = viewModel.fileURL {
                VideoPlayerView()
                    .frame(width: 196, height: 196)
                    .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                            ext: message?.fileMetaData?.file?.mimeType?.ext,
                                                            title: message?.fileMetaData?.name,
                                                            subtitle: message?.fileMetaData?.file?.originalName ?? ""))
                    .id(fileURL)
            }
        case .DOWNLOADING, .STARTED:
            CircularProgressView(percent: $viewModel.downloadPercent, config: DownloadVideoButtonView.config.circleConfig)
                .padding(8)
                .frame(maxWidth: DownloadVideoButtonView.config.circleProgressMaxWidth)
                .onTapGesture {
                    viewModel.pauseDownload()
                }
        case .PAUSED:
            Image(systemName: "pause.circle")
                .resizable()
                .padding(8)
                .font(.headline.weight(.thin))
                .foregroundColor(DownloadVideoButtonView.config.iconColor)
                .scaledToFit()
                .frame(width: DownloadVideoButtonView.config.iconWidth, height: DownloadVideoButtonView.config.iconHeight)
                .frame(maxWidth: DownloadVideoButtonView.config.circleProgressMaxWidth)
                .onTapGesture {
                    viewModel.resumeDownload()
                }
        case .UNDEFINED, .THUMBNAIL:
            if message?.isImage == true, let data = viewModel.tumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .blur(radius: 5, opaque: true)
                    .scaledToFit()
                    .zIndex(0)
            }

            Image(systemName: "arrow.down.circle")
                .resizable()
                .font(DownloadVideoButtonView.config.circleConfig.progressFont)
                .padding(8)
                .frame(width: DownloadVideoButtonView.config.iconWidth, height: DownloadVideoButtonView.config.iconHeight)
                .scaledToFit()
                .foregroundColor(DownloadVideoButtonView.config.iconColor)
                .zIndex(1)
                .onTapGesture {
                    viewModel.startDownload()
                }
        default:
            EmptyView()
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        FileView(conversation: thread, messageType: .file)
    }
}
