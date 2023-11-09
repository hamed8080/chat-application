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

struct VideoView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
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

    var body: some View {
        ForEach(viewModel.messages) { message in
            VideoRowView(message: message)
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(Color.App.divider)
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
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss
    @State var width: CGFloat? = 48
    @State var height: CGFloat? = 48

    var body: some View {
        HStack {
            let view = DownloadVideoButtonView()
                .frame(width: width, height: height)
                .padding(4)
            if let downloadVM = threadVM?.messageViewModel(for: message).downloadFileVM {
                view.environmentObject(downloadVM)
                    .onReceive(downloadVM.objectWillChange) { newValue in
                        if downloadVM.state == .completed {
                            height = nil
                            width = nil
                        }
                    }
            } else {
                view
            }

            VStack(alignment: .leading) {
                Text(message.fileMetaData?.name ?? message.messageTitle)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.text)
                HStack {
                    Text(message.time?.date.localFormattedTime ?? "" )
                        .foregroundColor(Color.App.hint)
                        .font(.iransansCaption2)
                    Spacer()
                    Text(message.fileMetaData?.file?.size?.toSizeString(locale: Language.preferredLocale) ?? "")
                        .foregroundColor(Color.App.hint)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        .contentShape(Rectangle())
        .onTapGesture {
            threadVM?.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
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
                VideoPlayerView()
                    .frame(width: 196, height: 196)
                    .environmentObject(VideoPlayerViewModel(fileURL: fileURL,
                                                            ext: message?.fileMetaData?.file?.mimeType?.ext,
                                                            title: message?.fileMetaData?.name,
                                                            subtitle: message?.fileMetaData?.file?.originalName ?? ""))
                    .id(fileURL)
            }
        case .downloading, .started, .paused, .undefined, .thumbnail:
            DownloadFileView(viewModel: viewModel, config: .detail)
                .frame(width: 72, height: 72)
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
