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
import TalkExtensions
import ActionableContextMenu

struct PictureView: View {
    @EnvironmentObject var detailViewModel: DetailViewModel
    let viewModel: DetailTabDownloaderViewModel
    @State var viewWidth: CGFloat = 0

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
        let spacing: CGFloat = 8
        let padding: CGFloat = 16
        let viewWidth = viewWidth - padding
        let itemWidthWithouthSpacing = viewModel.itemWidth(readerWidth: viewWidth)
        let itemWidth = itemWidthWithouthSpacing - spacing
        LazyVGrid(
            columns: Array(
                repeating: .init(
                    .flexible(
                        minimum: itemWidth,
                        maximum: itemWidth
                    ),
                    spacing: spacing
                ),
                count: viewModel.itemCount
            ),
            alignment: .leading,
            spacing: spacing
        ) {
            if viewWidth != 0 {
                MessageListPictureView(itemWidth: abs(itemWidth))
            }
        }
        .padding(padding)
        .onAppear {
            if viewModel.messages.count == 0 {
                viewModel.loadMore()
            }
        }
        .environmentObject(viewModel)
        .background {
            GeometryReader { reader in
                Color.clear.onAppear {
                    self.viewWidth = reader.size.width
                }
            }
        }
    }
}

struct MessageListPictureView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: DetailViewModel
    
    var body: some View {
        ForEach(viewModel.messages) { message in
            PictureRowView(message: message, itemWidth: itemWidth)
                .environmentObject(downloadMV(message))
                .id(message.id)
                .frame(width: itemWidth, height: itemWidth)
                .onAppear {
                    if viewModel.isCloseToLastThree(message) {
                        viewModel.loadMore()
                    }
                }
        }
        DetailLoading()
    }

    private func downloadMV(_ message: Message) -> DownloadFileViewModel {
        detailViewModel.threadVM?.historyVM.messageViewModel(for: message)?.downloadFileVM ?? DownloadFileViewModel(message: message)
    }
}

struct PictureRowView: View {
    let message: Message
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    @EnvironmentObject var appOverlayViewModel: AppOverlayViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: DetailViewModel
    let itemWidth: CGFloat

    init(message: Message, itemWidth: CGFloat) {
        self.message = message
        self.itemWidth = itemWidth
    }

    var body: some View {
        DownloadPictureButtonView(itemWidth: itemWidth)
            .frame(width: itemWidth, height: itemWidth)
            .clipped()
            .onTapGesture {
                appOverlayViewModel.galleryMessage = message
            }
            .customContextMenu(id: message.id, self: self.environmentObject(downloadVM)) {
                VStack {
                    ContextMenuButton(title: "General.showMessage", image: "message.fill") {
                        threadVM?.historyVM.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
                        viewModel.dismiss = true
                    }
                }
                .foregroundColor(.primary)
                .frame(width: 196)
                .background(MixMaterialBackground())
                .clipShape(RoundedRectangle(cornerRadius:((12))))
            }
    }
}

struct DownloadPictureButtonView: View {
    let itemWidth: CGFloat
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private var message: Message? { viewModel.message }

    var body: some View {
        switch viewModel.state {
        case .completed:
            if let fileURL = viewModel.fileURL, let scaledImage = fileURL.imageScale(width: 128)?.image {
                Image(cgImage: scaledImage)
                    .resizable()
                    .frame(width: itemWidth, height: itemWidth)
                    .scaledToFit()
                    .clipped()
                    .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
            }
        case .undefined, .thumbnail:
            ZStack {
                let data = viewModel.thumbnailData
                let image = UIImage(data: data ?? Data()) ?? UIImage()
                Image(uiImage: image)
                    .resizable()
                    .frame(width: itemWidth, height: itemWidth)
                    .scaledToFit()
                    .clipped()
                    .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
                    .zIndex(0)
                    .background(Color.App.dividerSecondary)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
                    .onAppear {
                        if viewModel.isInCache {
                            viewModel.state = .completed
                            viewModel.animateObjectWillChange()
                        } else {
                            if message?.isImage == true, !viewModel.isInCache, viewModel.thumbnailData == nil {
                                viewModel.downloadBlurImage(quality: 1.0, size: .SMALL)
                            }
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
