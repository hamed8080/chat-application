//
//  PictureView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct PictureView: View {
    let viewModel: DetailTabDownloaderViewModel
    @State var viewWidth: CGFloat = 0

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
    }

    var body: some View {
        let itemWidth = viewModel.itemWidth(readerWidth: viewWidth)
        LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: itemWidth, maximum: itemWidth), spacing: 0), count: viewModel.itemCount), spacing: 0) {
            if viewWidth != 0 {
                MessageListPictureView(itemWidth: itemWidth)
            }
        }
        .task {
            viewModel.loadMore()
        }
        .environmentObject(viewModel)
        .background {
            GeometryReader { reader in
                Color.clear.onAppear {
                    viewWidth = reader.size.width
                }
            }
        }
    }
}

struct MessageListPictureView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            PictureRowView(message: message, itemWidth: itemWidth)
                .id(message.id)
                .frame(width: itemWidth, height: itemWidth)
                .onAppear {
                    if viewModel.isCloseToLastThree(message) {
                        viewModel.loadMore()
                    }
                }
        }
        if viewModel.isLoading {
            LoadingView()
                .id("MessageListPictureViewLoading")
                .frame(width: 24, height: 24)
        }
    }
}

struct PictureRowView: View {
    let message: Message
    @EnvironmentObject var appOverlayViewModel: AppOverlayViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: DetailViewModel
    let itemWidth: CGFloat

    init(message: Message, itemWidth: CGFloat) {
        self.message = message
        self.itemWidth = itemWidth
    }

    var body: some View {
        let view = DownloadPictureButtonView(itemWidth: itemWidth)
            .frame(width: itemWidth, height: itemWidth)
            .clipped()
            .contextMenu {
                Button {
                    threadVM?.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
                    viewModel.dismiss = true
                } label: {
                    Label("Show Message", systemImage: "bubble.middle.top")
                }
            }.onTapGesture {
                appOverlayViewModel.galleryMessage = message
            }
        if let downloadVM = threadVM?.messageViewModel(for: message).downloadFileVM {
            view
                .environmentObject(downloadVM)
        } else {
            view
        }
    }
}

struct DownloadPictureButtonView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private var message: Message? { viewModel.message }
    private let config = DownloadPictureButtonView.config
    static var config: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = .green
        config.iconColor = .orange
        config.showSkeleton = true
        return config
    }()

    var body: some View {
        switch viewModel.state {
        case .COMPLETED:
            if let fileURL = viewModel.fileURL, let scaledImage = fileURL.imageScale(width: 128)?.image {
                Image(cgImage: scaledImage)
                    .resizable(resizingMode: .stretch)
                    .frame(width: itemWidth, height: itemWidth)
                    .scaledToFill()
                    .clipped()
                    .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
            }
        case .DOWNLOADING, .STARTED:
            if config.showSkeleton {
                Image(systemName: "photo.artframe")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.3)
                    .padding(8)
                    .frame(width: itemWidth, height: itemWidth)
                    .redacted(reason: .placeholder)
            } else {
                CircularProgressView(percent: $viewModel.downloadPercent, config: config.circleConfig)
                    .padding(8)
                    .frame(maxWidth: itemWidth)
                    .onTapGesture {
                        viewModel.pauseDownload()
                    }
            }
        case .PAUSED:
            Image(systemName: "pause.circle")
                .resizable()
                .padding(8)
                .font(.headline.weight(.thin))
                .foregroundColor(config.iconColor)
                .scaledToFit()
                .frame(width: itemWidth, height: itemWidth)
                .onTapGesture {
                    viewModel.resumeDownload()
                }
        case .UNDEFINED, .THUMBNAIL:
            ZStack {
                if message?.isImage == true, let data = viewModel.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable(resizingMode: .stretch)
                        .frame(width: itemWidth, height: itemWidth)
                        .scaledToFill()
                        .clipped()
                        .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
                        .zIndex(0)
                }

                Image(systemName: "arrow.down.circle")
                    .resizable()
                    .font(config.circleConfig.progressFont)
                    .padding(8)
                    .frame(width: config.iconWidth, height: config.iconHeight, alignment: .center)
                    .scaledToFill()
                    .foregroundColor(config.iconColor)
                    .zIndex(1)
                    .onTapGesture {
                        viewModel.startDownload()
                    }
                    .onAppear {
                        if message?.isImage == true, !viewModel.isInCache, viewModel.thumbnailData == nil {
                            viewModel.downloadBlurImage()
                        }
                    }
            }
            .frame(width: itemWidth, height: itemWidth)
        default:
            EmptyView()
        }
    }
}

struct PictureView_Previews: PreviewProvider {
    static var previews: some View {
        PictureView(conversation: MockData.thread, messageType: .podSpacePicture)
    }
}
