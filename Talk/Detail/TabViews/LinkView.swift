//
//  LinkView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct LinkView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        MessageListLinkView()
            .environmentObject(viewModel)
    }
}

struct MessageListLinkView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            LinkRowView(message: message)
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

struct LinkRowView: View {
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
                    .font(.iransansSubtitle)
            }
            Spacer()
            let view = DownloadLinkButtonView()
                .frame(width: 48, height: 48)
                .padding(4)
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

struct DownloadLinkButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    static var config: DownloadFileViewConfig = {
        var config: DownloadFileViewConfig = .small
        config.circleConfig.forgroundColor = .green
        config.iconColor = Color.main
        return config
    }()

    var body: some View {
        DownloadFileView(viewModel: veiwModel, config: DownloadFileButtonView.config)
            .frame(width: 72, height: 72)
    }
}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinkView(conversation: MockData.thread, messageType: .link)
    }
}
