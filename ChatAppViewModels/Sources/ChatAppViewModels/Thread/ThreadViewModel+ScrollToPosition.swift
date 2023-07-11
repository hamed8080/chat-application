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
    func scrollTo(_ uniqueId: String, _ animation: Animation?, anchor: UnitPoint?)
    func scrollToBottom(animation: Animation?)
    func scrollToLastMessageIfLastMessageIsVisible()
}

extension ThreadViewModel: ScrollToPositionProtocol {

    public func scrollTo(_ uniqueId: String, _ animation: Animation? = .spring(response: 0.05, dampingFraction: 0.8, blendDuration: 0.2), anchor: UnitPoint? = .center) {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            withAnimation(animation) {
                self?.scrollProxy?.scrollTo(uniqueId, anchor: anchor)
            }
        }
    }

    public func setNewOrigin(newOriginY: CGFloat) {
        scrollingUP = lastOrigin > newOriginY
        lastOrigin = newOriginY
        if scrollingUP, newOriginY < 0, canLoadMoreTop {
            moreTop(messages.first?.time?.advanced(by: -1))
        }
    }

    public func scrollToBottom(animation: Animation? = .easeInOut) {
        if let uniqueId = messages.last?.uniqueId {
            scrollTo(uniqueId, animation)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible() {
        if isAtBottomOfTheList {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.scrollToBottom()
            }
        }
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    func moveToMessageLocally(_ messageId: Int, highlight: Bool) -> Bool {
        if let uniqueId = messages.first(where: { $0.id == messageId })?.uniqueId {
            showHighlighted(uniqueId, messageId, highlight: highlight)
            return true
        }
        return false
    }

    func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true) {
        scrollTo(uniqueId, anchor: .bottom)
        if highlight {
            highlightMessage(messageId)
        }
    }

    func highlightMessage(_ messageId: Int) {
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
