//
//  ThreadUnreadMentionsViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine

public final class ThreadUnreadMentionsViewModel: ObservableObject {
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    public private(set) var unreadMentions: ContiguousArray<Message> = .init()
    private var cancelable: Set<AnyCancellable> = []
    public private(set) var hasMention: Bool = false
    private var objectId = UUID().uuidString
    private let UNREAD_MENTIONS_KEY: String

    public init(){
        UNREAD_MENTIONS_KEY = "UNREAD-MENTIONS-\(objectId)"
    }

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        hasMention = thread?.mentioned == true
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    public func scrollToMentionedMessage() async {
        viewModel?.scrollVM.scrollingUP = false//open sending unread counts if we scrolled up and there is a new messge where we have mentiond
        await viewModel?.moveToFirstUnreadMessage()
    }

    public func fetchAllUnreadMentions() {
        guard let threadId = thread?.id else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 25, offset: 0, order: "desc", unreadMentioned: true)
        RequestsManager.shared.append(prepend: UNREAD_MENTIONS_KEY, value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    public func setAsRead(id: Int?) {
        unreadMentions.removeAll(where: { $0.id == id })
        if unreadMentions.isEmpty {
            hasMention = false
        }
        animateObjectWillChange()
    }

    func onUnreadMentions(_ response: ChatResponse<[Message]>) {
        if response.subjectId == thread?.id, !response.cache, response.pop(prepend: UNREAD_MENTIONS_KEY) != nil, let unreadMentions = response.result {
            self.unreadMentions.removeAll()
            self.unreadMentions.append(contentsOf: unreadMentions)
            self.unreadMentions.sort(by: {$0.time ?? 0 < $1.time ?? 1})
            animateObjectWillChange()
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            onUnreadMentions(response)
        case .new(let response):
            onNewMesssage(response)
        default:
            break
        }
    }

    private func onNewMesssage(_ response: ChatResponse<Message>) {
        if response.subjectId == thread?.id, let message = response.result, !message.isMe(currentUserId: AppState.shared.user?.id ?? -1), message.mentioned == true {
            unreadMentions.append(message)
            hasMention = true
            animateObjectWillChange()
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
