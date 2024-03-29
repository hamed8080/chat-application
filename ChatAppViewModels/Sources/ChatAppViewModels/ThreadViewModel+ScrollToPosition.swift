//
//  ThreadViewModel+ScrollToPosition.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import ChatModels

public protocol ScrollToPositionProtocol {
    var canScrollToBottomOfTheList: Bool { get set }
    func setScrollToUniqueId(_ uniqueId: String)
    func scrollToBottom()
    func scrollToLastMessageIfLastMessageIsVisible()
    func updateScrollToLastSeenUniqueId()
    func setIfNeededToScrollToTheLastPosition(_ scrollingUP: Bool, _ message: Message)
}

extension ThreadViewModel: ScrollToPositionProtocol {
    public func updateScrollToLastSeenUniqueId() {
        if scrollToUniqueId == nil, let uniqueId = messages.first(where: { $0.id == thread?.lastSeenMessageId })?.uniqueId {
            setScrollToUniqueId(uniqueId)
        }
    }

    public func setScrollToUniqueId(_ uniqueId: String) {
        scrollToUniqueId = uniqueId
    }

    public func scrollToBottom() {
        if let uniqueId = messages.last?.uniqueId {
            setScrollToUniqueId(uniqueId)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible() {
        if canScrollToBottomOfTheList {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.scrollToBottom()
            }
        }
    }

    /// Check if the user scroll down to the end item of the list and right now last item is visible
    /// so new messages should be added and scroll to last item automatically.
    public func setIfNeededToScrollToTheLastPosition(_ scrollingUP: Bool, _ message: Message) {
        if scrollingUP == false, message == messages.last {
            canScrollToBottomOfTheList = true
        } else {
            canScrollToBottomOfTheList = false
        }
    }
}
