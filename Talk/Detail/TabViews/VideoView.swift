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
import TalkModels
import ActionableContextMenu

struct VideoView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType, tabName: "Video")
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
            .onAppear {
                if viewModel.messages.count == 0 {
                    viewModel.loadMore()
                }
            }
        MessageListVideoView()
            .padding(.top, 8)
            .environmentObject(viewModel)
    }
}

struct MessageListVideoView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel
    @EnvironmentObject var detailViewModel: DetailViewModel
    
    var body: some View {
        ForEach(viewModel.messages) { message in
            VideoRowView(message: message)
                .environmentObject(viewModel.downloadVM(message: message))
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(Color.App.dividerPrimary)
                            .frame(height: 0.5)
                            .padding(.leading)
                    }
                }
                .onAppear {
                    if message == viewModel.messages.last {
                        viewModel.loadMore()
                    }
                }
        }
        DetailLoading()
    }
}

struct VideoRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var downloadVM: DownloadFileViewModel
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss
    @State var width: CGFloat? = 48
    @State var height: CGFloat? = 48
    @State var shareDownloadedFile = false
    @EnvironmentObject var downloadViewModel: DownloadFileViewModel

    var body: some View {
        HStack {
            DownloadVideoButtonView()
                .frame(width: width, height: height)
                .padding(4)
                .onReceive(downloadViewModel.objectWillChange) { newValue in
                    if downloadViewModel.state == .completed {
                        height = nil
                        width = nil
                    }
                }

            VStack(alignment: .leading) {
                Text(message.fileMetaData?.name ?? message.messageTitle)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack {
                    Text(message.time?.date.localFormattedTime ?? "" )
                        .foregroundColor(Color.App.textSecondary)
                        .font(.iransansCaption2)
                    Spacer()
                    Text(message.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) ?? "")
                        .foregroundColor(Color.App.textSecondary)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        .contentShape(Rectangle())
        .background(Color.App.bgPrimary)
        .onTapGesture {
            if downloadViewModel.state != .completed {
                downloadViewModel.startDownload()
            } else {
                AppState.shared.objectsContainer.audioPlayerVM.toggle()
            }
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

struct DownloadVideoButtonView: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    private var message: Message? { viewModel.message }

    var body: some View {
        switch viewModel.state {
        case .completed:
            if message?.isVideo == true, let fileURL = viewModel.fileURL {
                FullScreenPlayer(fileURL: fileURL, message: message)
            }
        case .downloading, .started, .paused, .undefined, .thumbnail:
            DownloadFileView(viewModel: viewModel)
                .frame(width: 72, height: 72)
        default:
            EmptyView()
        }
    }
}

struct FullScreenPlayer: View {
    let fileURL: URL
    @StateObject var playerVM: VideoPlayerViewModel
    @State var showFullScreen = false

    init(fileURL: URL, message: Message?, showFullScreen: Bool = false) {
        self.fileURL = fileURL
        self._playerVM = StateObject(wrappedValue: VideoPlayerViewModel(fileURL: fileURL,
                                             ext: message?.fileMetaData?.file?.mimeType?.ext,
                                             title: message?.fileMetaData?.name,
                                             subtitle: message?.fileMetaData?.file?.originalName ?? ""))
        self.showFullScreen = showFullScreen
    }

    var body: some View {
        Button {
            playerVM.toggle()
            playerVM.animateObjectWillChange()
            showFullScreen = true
        } label: {
            ZStack {
                Image(systemName: "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.App.textPrimary)
            }
            .frame(width: 36, height: 36)
            .background(Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .contentShape(Rectangle())
        }
        .frame(width: 48, height: 48)
        .padding(4)
        .fullScreenCover(isPresented: $showFullScreen) {
            if let player = playerVM.player {
                PlayerViewRepresentable(player: player, showFullScreen: $showFullScreen)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime)) { _ in
            showFullScreen = false
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        FileView(conversation: thread, messageType: .file)
    }
}
