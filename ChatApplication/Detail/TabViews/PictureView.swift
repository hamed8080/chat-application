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

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        MessageListPictureView()
            .environmentObject(viewModel)
    }
}

struct MessageListPictureView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @Environment(\.horizontalSizeClass) var size

    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 128, maximum: 128), spacing: 0, alignment: .center), count: size == .compact ? 3 : 8), spacing: 4) {
            ForEach(viewModel.messages) { message in
                PictureRowView(message: message)
                    .onAppear {
                        if viewModel.isCloseToLastThree(message) {
                            viewModel.loadMore()
                        }
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
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var presentViewGallery = false

    var body: some View {
        DownloadPictureButtonView()
            .environmentObject(DownloadFileViewModel(message: message))
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
            if let fileURL = viewModel.fileURL, let scaledImage = fileURL.imageScale(width: 96)?.image {
                Image(cgImage: scaledImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 128)
                    .clipped()
                    .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
            }
        case .DOWNLOADING, .STARTED:
            CircularProgressView(percent: $viewModel.downloadPercent, config: config.circleConfig)
                .padding(8)
                .frame(maxWidth: config.circleProgressMaxWidth)
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
                .frame(width: config.iconWidth, height: config.iconHeight)
                .frame(maxWidth: config.circleProgressMaxWidth)
                .onTapGesture {
                    viewModel.resumeDownload()
                }
        case .UNDEFINED, .THUMBNAIL:
            ZStack {
                if message.isImage, let data = viewModel.tumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 128, height: 128)
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
