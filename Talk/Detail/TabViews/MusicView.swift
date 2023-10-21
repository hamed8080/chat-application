//
//  MusicView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct MusicView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
        MessageListMusicView()
            .environmentObject(viewModel)
    }
}

struct MessageListMusicView: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        ForEach(viewModel.messages) { message in
            MusicRowView(message: message)
                .overlay(alignment: .bottom) {
                    if message != viewModel.messages.last {
                        Rectangle()
                            .fill(Color.dividerDarkerColor.opacity(0.3))
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
        if viewModel.isLoading {
            LoadingView()
        }
    }
}

struct MusicRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            let view = DownloadMusicButtonView()
                .frame(width: 48, height: 48)
                .padding(4)
            if let downloadVM = threadVM?.messageViewModel(for: message).downloadFileVM {
                view.environmentObject(downloadVM)
            } else {
                view
            }

            VStack(alignment: .leading) {
                Text(message.fileMetaData?.name ?? message.messageTitle)
                    .font(.iransansBody)
                    .foregroundStyle(Color.messageText)
                HStack {
                    Text(message.time?.date.timeAgoSinceDateCondense ?? "" )
                        .foregroundColor(Color.hint)
                        .font(.iransansCaption2)
                    Spacer()
                    Text(message.fileMetaData?.file?.size?.toSizeString ?? "")
                        .foregroundColor(Color.hint)
                        .font(.iransansCaption3)
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        .onTapGesture {
            threadVM?.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }
    }
}

struct DownloadMusicButtonView: View {
    @EnvironmentObject var veiwModel: DownloadFileViewModel
    var body: some View {
        DownloadFileView(viewModel: veiwModel, config: .detail)
            .frame(width: 72, height: 72)
    }
}

struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicView(conversation: MockData.thread, messageType: .podSpaceSound)
    }
}
