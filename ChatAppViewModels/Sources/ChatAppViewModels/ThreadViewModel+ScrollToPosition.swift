//
//  ThreadViewModel+ScrollToPosition.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import ChatModels
import ChatDTO
import ChatCore
import SwiftUI

public protocol ScrollToPositionProtocol {
    var canScrollToBottomOfTheList: Bool { get set }
    func scrollTo(_ uniqueId: String, animation: Animation?, anchor: UnitPoint?)
    func scrollToBottom()
    func scrollToLastMessageIfLastMessageIsVisible()
}

extension ThreadViewModel: ScrollToPositionProtocol {

    public func scrollTo(_ uniqueId: String, animation: Animation? = .easeInOut, anchor: UnitPoint? = .bottom) {
        objectWillChange.send()
        Timer.scheduledTimer(withTimeInterval: 0.002, repeats: false) { [weak self] timer in
            withAnimation(animation) {
                self?.scrollProxy?.scrollTo(uniqueId, anchor: anchor)
            }
        }
    }

    public func setNewOrigin(newOriginY: CGFloat) {
        scrollingUP = lastOrigin > newOriginY
        lastOrigin = newOriginY
    }

    public func scrollToBottom() {
        if let uniqueId = messages.last?.uniqueId {
            scrollTo(uniqueId)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible() {
        if canScrollToBottomOfTheList {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.scrollToBottom()
            }
        }
    }

    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        if moveToMessageLocally(messageId, highlight: highlight) { return }
        let toTimeReq = GetHistoryRequest(threadId: threadId, count: 25, offset: 0, order: "desc", toTime: time.advanced(by: 100), readOnly: readOnly)
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: 25, fromTime: time.advanced(by: 100), offset: 0, order: "desc", readOnly: readOnly)
        requests["TO_TIME-\(toTimeReq.uniqueId)"] = (toTimeReq, messageId, highlight)
        requests["FROM_TIME-\(fromTimeReq.uniqueId)"] = (fromTimeReq, messageId, highlight)
        ChatManager.activeInstance?.message.history(toTimeReq)
        ChatManager.activeInstance?.message.history(fromTimeReq)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ messageId: Int, highlight: Bool) -> Bool {
        if let uniqueId = messages.first(where: { $0.id == messageId })?.uniqueId {
            showHighlighted(uniqueId, messageId, highlight: highlight)
            return true
        }
        return false
    }

    func onMoveToTime(_ response: ChatResponse<[Message]>) {
        onMoveTime(response: response, key: "TO_TIME")
    }

    func onMoveFromTime(_ response: ChatResponse<[Message]>) {
        onMoveTime(response: response, key: "FROM_TIME")
    }

    func onMoveTime(response: ChatResponse<[Message]>, key: String) {
        guard !response.cache,
              let uniqueId = response.uniqueId,
              let messages = response.result,
              let tuple = requests["\(key)-\(uniqueId)"] as? (request: GetHistoryRequest, messageId: Int, highlight: Bool)
        else { return }
        appendMessages(messages)
        if let messageIdUniqueId = self.messages.first(where: {$0.id == tuple.messageId})?.uniqueId {
            showHighlighted(messageIdUniqueId, tuple.messageId, highlight: tuple.highlight)
        }
        requests.removeValue(forKey: "\(key)-\(uniqueId)")
    }

    private func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true) {
        scrollTo(uniqueId)
        if highlight {
            highlightMessage(messageId)
        }
    }

    private func highlightMessage(_ messageId: Int) {
        withAnimation(.easeInOut) {
            highliteMessageId = messageId
            objectWillChange.send()
        }
        highlightTimer?.invalidate()
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            withAnimation(.easeInOut) {
                self?.highliteMessageId = nil
                self?.objectWillChange.send()
            }
        }
    }
}
