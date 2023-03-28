//
//  MediaView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import FanapPodChatSDK
import SwiftUI

struct MediaView: View {
    var thread: Conversation
    @StateObject var viewModel: AttachmentsViewModel = .init()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        List {
            LazyVGrid(columns: columns, alignment: .center, spacing: 4) {
                ForEach(viewModel.model.messages) { picture in
                    MediaPicture(picture: picture)
                        .onAppear {
                            if viewModel.model.messages.last == picture {
                                viewModel.loadMore()
                            }
                        }
                }
            }
            .noSeparators()
            .listRowBackground(Color.clear)
        }
        .padding(8)
        .onAppear {
            viewModel.thread = thread
            viewModel.getPictures()
        }
    }
}

struct MediaPicture: View {
    var picture: Message

    var body: some View {
        ImageLaoderView(url: picture.fileMetaData?.file?.link)
            .id("\(picture.fileMetaData?.file?.link ?? "")\(picture.id ?? 0)")
            .scaledToFit()
            .frame(height: 128)
            .padding(16)
    }
}

final class AttachmentsViewModel: ObservableObject {
    var thread: Conversation?
    @Published var isLoading = false
    @Published var model = AttachmentModel()

    func getPictures() {
        guard let threadId = thread?.id else { return }

        ChatManager.activeInstance?.getHistory(.init(threadId: threadId, count: model.count, messageType: MessageType.podSpacePicture.rawValue, offset: model.offset)) { [weak self] response in
            if let messages = response.result {
                self?.model.appendMessages(messages: messages)
                self?.model.setHasNext(response.pagination?.hasNext ?? false)
            }
            self?.isLoading = false
        } cacheResponse: { [weak self] response in
            if let messages = response.result {
                self?.model.setMessages(messages: messages)
            }
        }
    }

    func loadMore() {
        if !model.hasNext || isLoading { return }
        isLoading = true
        model.preparePaginiation()
        getPictures()
    }
}

struct AttachmentModel {
    private(set) var count = 50
    private(set) var offset = 0
    private(set) var totalCount = 0
    private(set) var messages: [Message] = []
    private(set) var hasNext: Bool = false

    mutating func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    mutating func preparePaginiation() {
        offset = messages.count
    }

    mutating func setContentCount(totalCount: Int) {
        self.totalCount = totalCount
    }

    mutating func setMessages(messages: [Message]) {
        self.messages = messages
        sort()
    }

    mutating func appendMessages(messages: [Message]) {
        self.messages.append(contentsOf: filterNewMessagesToAppend(serverMessages: messages))
        sort()
    }

    /// Filter only new messages prevent conflict with cache messages
    mutating func filterNewMessagesToAppend(serverMessages: [Message]) -> [Message] {
        let ids = messages.map(\.id)
        let newMessages = serverMessages.filter { message in
            !ids.contains { id in
                id == message.id
            }
        }
        return newMessages
    }

    mutating func appendMessage(_ message: Message) {
        messages.append(message)
        sort()
    }

    mutating func clear() {
        offset = 0
        count = 15
        totalCount = 0
        messages = []
    }

    mutating func sort() {
        messages = messages.sorted { m1, m2 in
            if let t1 = m1.time, let t2 = m2.time {
                return t1 < t2
            } else {
                return false
            }
        }
    }
}

struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        MediaView(thread: MockData.thread)
    }
}
