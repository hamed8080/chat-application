//
//  PictureView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct PictureView: View {
    @State var viewModel: DetailTabDownloaderViewModel
    @State var viewWidth: CGFloat = 0

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        let itemWidth = viewModel.itemWidth(readerWidth: viewWidth)
        LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: itemWidth, maximum: itemWidth), spacing: 0), count: viewModel.itemCount), spacing: 0) {
            if viewWidth != 0 {
                MessageListPictureView(viewWidth: viewWidth)
            }
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
    let viewWidth: CGFloat
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        let itemWidth = viewModel.itemWidth(readerWidth: viewWidth)
        ForEach(viewModel.messages) { message in
            PictureRowView(message: message, itemWidth: itemWidth)
                .onAppear {
                    if viewModel.isCloseToLastThree(message) {
                        viewModel.loadMore()
                    }
                }
        }
        if viewModel.isLoading {
            LoadingView()
        }
    }
}

struct PictureRowView: View {
    let message: Message
    let downloadVM: DownloadFileViewModel
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @State private var presentViewGallery = false
    let itemWidth: CGFloat

    init(message: Message, itemWidth: CGFloat) {
        self.message = message
        self.itemWidth = itemWidth
        downloadVM = .init(message: message)
    }

    var body: some View {
        DownloadPictureButtonView(itemWidth: itemWidth)
            .environmentObject(downloadVM)
            .frame(width: itemWidth, height: itemWidth)
            .clipped()
            .contextMenu {
                Button {
                    threadVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
                    viewModel.dismiss = true
                } label: {
                    Label("Show Message", systemImage: "bubble.middle.top")
                }
            }.onTapGesture {
                presentViewGallery = true
            }
            .fullScreenCover(isPresented: $presentViewGallery) {
                GalleryView(viewModel: GalleryViewModel(message: message))
                    .id(message.id)
            }
    }
}

struct DownloadPictureButtonView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private var message: Message { viewModel.message }
    private let config = DownloadPictureButtonView.config
    static var config: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = .green
        config.iconColor = .orange
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
            CircularProgressView(percent: $viewModel.downloadPercent, config: config.circleConfig)
                .padding(8)
                .frame(maxWidth: itemWidth)
                .onTapGesture {
                    viewModel.pauseDownload()
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
                if message.isImage, let data = viewModel.tumbnailData, let image = UIImage(data: data) {
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
                    .scaledToFit()
                    .foregroundColor(config.iconColor)
                    .zIndex(1)
                    .onTapGesture {
                        viewModel.startDownload()
                    }
                    .onAppear {
                        if message.isImage, !viewModel.isInCache, viewModel.tumbnailData == nil {
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
