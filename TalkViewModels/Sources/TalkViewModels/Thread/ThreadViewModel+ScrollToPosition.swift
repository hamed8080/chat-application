//
//  ThreadViewModel+ScrollToPosition.swift
//  TalkViewModels
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
    func scrollToBottom(animation: Animation?)
    func scrollToLastMessageIfLastMessageIsVisible(_ message: Message)
}

extension ThreadViewModel: ScrollToPositionProtocol {

    private func scrollTo(_ uniqueId: String, delay: TimeInterval = TimeInterval(0.6), _ animation: Animation? = .easeInOut, anchor: UnitPoint? = .bottom) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            withAnimation(animation) {
                self?.scrollProxy?.scrollTo(uniqueId, anchor: anchor)
            }
        }

         /// Ensure the view is shown as a result of SwiftUI can't properly move for the first time
        Timer.scheduledTimer(withTimeInterval: .init(1.5), repeats: false) { [weak self] _ in
            withAnimation(animation) {
                self?.scrollProxy?.scrollTo(uniqueId, anchor: anchor)
            }
        }
    }

    public func scrollToBottom(animation: Animation? = .easeInOut) {
        if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            moveToTime(time, messageId, highlight: false)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: Message) {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, delay: 0.1, .easeInOut)
        }
    }

    func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true) {
        scrollTo(uniqueId, anchor: .bottom)
        if highlight {
            NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
        }
    }
}
