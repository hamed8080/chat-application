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
import TalkExtensions

struct LinkView: View {
    @State var viewModel: DetailTabDownloaderViewModel

    init(conversation: Conversation, messageType: MessageType) {
        viewModel = .init(conversation: conversation, messageType: messageType)
        viewModel.loadMore()
    }

    var body: some View {
        StickyHeaderSection(header: "", height:  4)
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

struct LinkRowView: View {
    let message: Message
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: DetailViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.hintText)
                .frame(width: 36, height: 36)
                .cornerRadius(8)
                .overlay(alignment: .center) {
                    Image(systemName: "link")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.hint)
                }
            VStack(alignment: .leading) {
                Text(message.markdownTitle)
                    .font(.iransansBody)
            }
            Spacer()
        }
        .padding()
        .onTapGesture {
            threadVM?.moveToTime(message.time ?? 0, message.id ?? -1, highlight: true)
            viewModel.dismiss = true
        }
    }
}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinkView(conversation: MockData.thread, messageType: .link)
    }
}
