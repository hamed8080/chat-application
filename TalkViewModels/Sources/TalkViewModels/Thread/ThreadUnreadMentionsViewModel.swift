//
//  ThreadUnreadMentionsViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import ChatCore
import ChatModels
import ChatDTO
import Combine

public final class ThreadUnreadMentionsViewModel: ObservableObject {
    let thread: Conversation
    @Published public private(set) var unreadMentions: ContiguousArray<Message> = .init()
    private var cancelable: Set<AnyCancellable> = []
    public private(set) var hasMention: Bool = false
    public weak var threadVM: ThreadViewModel? {
        didSet {
            hasMention = thread.mentioned == true
        }
    }

    public static func == (lhs: ThreadUnreadMentionsViewModel, rhs: ThreadUnreadMentionsViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public init(thread: Conversation) {
        self.thread = thread
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

    public func scrollToMentionedMessage() {
        threadVM?.scrollVM.scrollingUP = false//open sending unread counts if we scrolled up and there is a new messge where we have mentiond
        threadVM?.moveToFirstUnreadMessage()
    }

    public func fetchAllUnreadMentions() {
        let req = GetHistoryRequest(threadId: thread.id ?? -1, count: 25, offset: 0, order: "desc", unreadMentioned: true)
        RequestsManager.shared.append(prepend: "UnreadMentions", value: req)
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
        if !response.cache, response.pop(prepend: "UnreadMentions") != nil, let unreadMentions = response.result {
            self.unreadMentions.removeAll()
            self.unreadMentions.append(contentsOf: unreadMentions)
            self.unreadMentions.sort(by: {$0.time ?? 0 < $1.time ?? 1})
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
        if let message = response.result, !message.isMe(currentUserId: AppState.shared.user?.id ?? -1), message.mentioned == true {
            unreadMentions.append(message)
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
