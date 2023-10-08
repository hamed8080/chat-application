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

struct FileView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        MessageListFileView()
            .environmentObject(viewModel)
    }
}

struct MessageListFileView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            FileRowView(message: message)
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

struct FileRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
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
            let view = DownloadFileButtonView()
            if let downloadVM = threadVM?.messageViewModel(for: message).downloadFileVM {
                view.environmentObject(downloadVM)
            } else {
                view
            }
        }
        .padding([.leading, .trailing])
        .onTapGesture {
            threadVM?.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }
    }
}

struct DownloadFileButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    static var config: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = .green
        config.iconColor = Color.main
        config.showSkeleton = false
        return config
    }()

    var body: some View {
        DownloadFileView(viewModel: veiwModel, config: DownloadFileButtonView.config)
            .frame(width: 48, height: 48)
            .padding(4)
    }
}

struct FileView_Previews: PreviewProvider {
    static let thread = MockData.thread

    static var previews: some View {
        FileView(conversation: thread, messageType: .file)
    }
}
