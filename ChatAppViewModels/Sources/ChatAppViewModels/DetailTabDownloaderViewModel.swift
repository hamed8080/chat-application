//
//  DetailTabDownloaderViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import ChatDTO
import ChatModels
import Combine
import SwiftUI

public class DetailTabDownloaderViewModel: ObservableObject {
    public private(set) var messages: [Message] = []
    private var conversation: Conversation
    private var offset = 0
    private var requests: [String: GetHistoryRequest] = [:]
    private var cancelable = Set<AnyCancellable>()
    public private(set) var isLoading = false
    public private(set) var hasNext = true
    private let messageType: MessageType
    private let count = 25

    public init(conversation: Conversation, messageType: MessageType) {
        self.conversation = conversation
        self.messageType = messageType
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case let .history(response):
            if !response.cache, let uniqueId = response.uniqueId, requests[uniqueId] != nil, response.subjectId == conversation.id, let messages = response.result {
                messages.forEach { message in
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                    }
                }
                self.messages.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
                requests.removeValue(forKey: uniqueId)
                isLoading = false
                hasNext = response.hasNext
                withAnimation {
                    objectWillChange.send()
                }
            }
        default:
            break
        }
    }

    public func isCloseToLastThree(_ message: Message) -> Bool {
        let index = Array<Message>.Index(messages.count - 3)
        if messages.indices.contains(index), messages[index].id == message.id {
            return true
        } else {
            return false
        }
    }

    public func loadMore() {
        guard let conversationId = conversation.id, !isLoading, hasNext else { return }
        let req: GetHistoryRequest = .init(threadId: conversationId, count: count, messageType: messageType.rawValue, offset: offset)
        offset += count
        requests[req.uniqueId] = req
        isLoading = true
        ChatManager.activeInstance?.message.history(req)
    }
}
