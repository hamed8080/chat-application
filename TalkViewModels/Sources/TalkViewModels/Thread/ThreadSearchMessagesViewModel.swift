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
    @Published public private(set) var searchedMessages: [Message] = []
    public var searchTextTimer: Timer?
    private var searchOffset: Int = 0
    private var cancelable: Set<AnyCancellable> = []
    public var isInSearchMode: Bool = false

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
    }

    public func searchInsideThread(text: String, offset: Int = 0) {
        searchTextTimer?.invalidate()
        searchTextTimer = nil
        searchTextTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.doSearch(text: text, offset: offset)
        }
    }

    public func doSearch(text: String, offset: Int = 0) {
        isInSearchMode = text.count >= 2
        animateObjectWillChange()
        guard text.count >= 2 else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 50, offset: searchOffset, query: "\(text)")
        RequestsManager.shared.append(prepend: "SEARCH", value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    func onSearch(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "SEARCH") != nil else { return }
        searchedMessages.removeAll()
        response.result?.forEach { message in
            if !(searchedMessages.contains(where: { $0.id == message.id })) {
                searchedMessages.append(message)
            }
        }
        animateObjectWillChange()
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
}
