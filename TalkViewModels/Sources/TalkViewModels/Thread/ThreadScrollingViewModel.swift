//
//  ThreadScrollingViewModel.swift
//
//
//  Created by hamed on 12/24/23.
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

public final class ThreadScrollingViewModel: ObservableObject {
    public var canScrollToBottomOfTheList: Bool = false
    public var isProgramaticallyScroll: Bool = false
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    public weak var threadVM: ThreadViewModel!
    private var thread: Conversation { threadVM!.thread }
    public var isAtBottomOfTheList: Bool = false

    init() {}

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
            threadVM?.historyVM.moveToTime(time, messageId, highlight: false)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: Message) {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            scrollTo(uniqueId, delay: 0.1, .easeInOut)
        }
    }

    func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, anchor: UnitPoint? = .bottom) {
        scrollTo(uniqueId, anchor: anchor)
        if highlight {
            NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
        }
    }

    public func disableExcessiveLoading() {
        isProgramaticallyScroll = true
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.isProgramaticallyScroll = false
        }
    }
}
