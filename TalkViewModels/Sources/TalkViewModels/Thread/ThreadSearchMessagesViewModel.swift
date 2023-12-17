//
//  ThreadSearchMessagesViewModel.swift
//  
//
//  Created by hamed on 11/27/23.
//

import Foundation
import ChatModels
import Chat
import ChatCore
import ChatDTO
import TalkModels
import Combine

public final class ThreadSearchMessagesViewModel: ObservableObject {
    private let threadId: Int
    @Published public private(set) var searchedMessages: ContiguousArray<Message> = .init()
    private var cancelable: Set<AnyCancellable> = []
    public var isInSearchMode: Bool = false
    private var offset = 0
    private let count = 50
    @Published public var searchText: String = ""
    private var hasMore = true
    @Published public var isLoading = false

    public static func == (lhs: ThreadSearchMessagesViewModel, rhs: ThreadSearchMessagesViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    public init(threadId: Int) {
        self.threadId = threadId
        setupNotificationObservers()
    }

    public func cancel() {
        isInSearchMode = false
        searchedMessages.removeAll()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink { [weak self] event in
                self?.onChatEvent(event)
            }
            .store(in: &cancelable)

        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.doSearch(text: newValue)
            }
            .store(in: &cancelable)

        RequestsManager.shared.$cancelRequest
            .sink { [weak self] newValue in
                if let newValue {
                    self?.onCancelTimer(key: newValue)
                }
            }
            .store(in: &cancelable)
    }

    public func doSearch(text: String, offset: Int = 0) {
        isInSearchMode = text.count >= 2
        searchedMessages.removeAll()
        animateObjectWillChange()
        guard text.count >= 2 else { return }
        isLoading = true
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: offset, query: "\(text)")
        RequestsManager.shared.append(prepend: "SEARCH", value: req)
        ChatManager.activeInstance?.message.history(req)
        self.offset = offset + count
    }

    public func loadMore() {
        if hasMore {
            doSearch(text: searchText)
        }
    }

    func onSearch(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            isLoading = true
            guard response.value(prepend: "SEARCH") != nil else { return }
            response.result?.forEach { message in
                if !(searchedMessages.contains(where: { $0.id == message.id })) {
                    searchedMessages.append(message)
                }
            }
            if !response.cache, !response.hasNext {
                hasMore = false
            }
            animateObjectWillChange()
        }
    }
    
    public func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        default:
            break
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            onSearch(response)
        default:
            break
        }
    }


    private func onCancelTimer(key: String) {
        isLoading = false
        animateObjectWillChange()
    }
}
