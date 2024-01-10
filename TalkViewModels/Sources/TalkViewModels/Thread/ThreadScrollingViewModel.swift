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

    @MainActor
    private func scrollTo(_ uniqueId: String, delay: TimeInterval = TimeInterval(0.6), _ animation: Animation? = .easeInOut, anchor: UnitPoint? = .bottom) async {
        try? await Task.sleep(for: .milliseconds(delay))
        withAnimation(animation) {
            scrollProxy?.scrollTo(uniqueId, anchor: anchor)
        }

        /// Ensure the view is shown as a result of SwiftUI can't properly move for the first time
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(animation) {
            scrollProxy?.scrollTo(uniqueId, anchor: anchor)
        }
    }

    public func scrollToBottom(animation: Animation? = .easeInOut) {
        if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            threadVM?.historyVM.moveToTime(time, messageId, highlight: false)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: Message) async {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            await scrollTo(uniqueId, delay: 0.1, .easeInOut)
        }
    }

    @MainActor
    func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, anchor: UnitPoint? = .bottom) async {
        if highlight {
            NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
        }
        await scrollTo(uniqueId, anchor: anchor)
    }

    public func disableExcessiveLoading() {
        Task.detached { [weak self] in
            self?.isProgramaticallyScroll = true
            try? await Task.sleep(for: .milliseconds(2))
            self?.isProgramaticallyScroll = false
        }
    }
}
