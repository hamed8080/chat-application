//
//  HistorySeenViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import Combine
import ChatModels
import Logger
import OSLog
import Chat
import TalkModels

public final class HistorySeenViewModel: ObservableObject {
    private weak var threadVM: ThreadViewModel?
    private var historyVM: ThreadHistoryViewModel? { threadVM?.historyVM }
    private var seenPublisher = PassthroughSubject<Message, Never>()
    private var cancelable: Set<AnyCancellable> = []
    private var thread: Conversation { threadVM?.thread ?? Conversation(id: 0) }
    private var isScrollingUp: Bool { threadVM?.scrollVM.scrollingUP == true }
    private let queue = DispatchQueue(label: "SEEN_SERIAL_QUEUE")    
    private var threadId: Int { thread.id ?? 0 }
    private var threadsVM: ThreadsViewModel { threadVM?.threadsViewModel ?? .init() }

    public init(threadViewModel: ThreadViewModel) {
        self.threadVM = threadViewModel
        seenPublisher
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.sendSeen(for: newValue)
            }
            .store(in: &cancelable)
    }

    internal func onAppear(_ message: Message) {
        queue.sync {
            if !canReduce(for: message) { return }
            let isLastUnread = isLastUnreadCount()
            if isLastUnread {
                sendLastMessageSeen()
            } else if !isLastUnread, let prevMsg = historyVM?.previous(message) {
                let newUnread = newLocalUnreadCount(for: prevMsg)
                if newUnread == 1 {
                    sendLastMessageSeen()
                } else {
                    logMessageApperance(prevMsg, appeard: true, isUp: false)
                    sendSeenAndReduceUnredaCountLocally(prevMsg)
                }
            }
        }
    }

    private func sendLastMessageSeen() {
        guard let message = thread.lastMessageVO else { return }
        logMessageApperance(message, appeard: true, isUp: false)
        sendSeenAndReduceUnredaCountLocally(message)
    }

    private func isLastUnreadCount() -> Bool {
        return thread.unreadCount ?? 0 == 1
    }

    private func canReduce(for message: Message) -> Bool {
        if isScrollingUp { return false }
        if thread.unreadCount ?? 0 == 0 { return false }
        if message.id == LocalId.emptyMessageSlot.rawValue { return false }
        if message.id == LocalId.unreadMessageBanner.rawValue { return false }
        return message.id ?? 0 > thread.lastSeenMessageId ?? 1
    }

    private func sendSeenAndReduceUnredaCountLocally(_ message: Message) {
        reduceUnreadCountLocaly(message)
        seenPublisher.send(message)
    }

    /// We reduce it locally to keep the UI Sync and user feels it really read the message.
    /// However, we only send seen request with debouncing
    private func reduceUnreadCountLocaly(_ message: Message) {
        if let newUnreadCount = newLocalUnreadCount(for: message) {
            thread.unreadCount = newUnreadCount
            reduceThreadListLocally(to: newUnreadCount)
        }
        reduceLastMessageLocally(message)
    }

    private func reduceThreadListLocally(to newUnreadCount: Int) {
        if let index = threadsVM.threads.firstIndex(where: {$0.id == threadId}) {
            threadsVM.threads[index].unreadCount = newUnreadCount
        }
        threadsVM.animateObjectWillChange()
        animateObjectWillChange()
    }

    /// We do this to remove number 1 as fast as the user scrolls to the last Message in the thread
    /// If we remove these lines it will work, however,
    /// we should wait for the server's response to remove the number 1 unread count when the user scrolls fast.
    private func reduceLastMessageLocally(_ message: Message) {
        if thread.unreadCount == 1, message.id == thread.lastMessageVO?.id {
            if let index = threadsVM.threads.firstIndex(where: {$0.id == threadId}) {
                threadsVM.threads[index].unreadCount = 0
                threadsVM.animateObjectWillChange()
            }
            threadVM?.animateObjectWillChange()
        }
    }

    private func newLocalUnreadCount(for message: Message) -> Int? {
        let messageId = message.id ?? -1
        let currentUnreadCount = thread.unreadCount ?? -1
        if currentUnreadCount > 0, messageId > thread.lastSeenMessageId ?? 0 {
            let newUnreadCount = currentUnreadCount - 1
            return newUnreadCount
        }
        return nil
    }

    private func sendSeen(for message: Message) {
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if let messageId = message.id, !isMe {
            thread.lastSeenMessageId = messageId
            log("send seen for message:\(message.messageTitle) with id:\(messageId)")
            ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
        }
    }

    internal func sendSeenForAllUnreadMessages() {
        if let message = thread.lastMessageVO,
           message.seen == nil || message.seen == false,
           message.participant?.id != AppState.shared.user?.id,
           thread.unreadCount ?? 0 > 0
        {
            sendSeen(for: message)
        }
    }

    func logMessageApperance(_ message: Message, appeard: Bool, isUp: Bool? = nil) {
#if DEBUG
        let dir = isUp == true ? "UP" : (isUp == false ? "DOWN" : "")
        let messageId = message.id ?? 0
        let uniqueId = message.uniqueId ?? ""
        let text = message.message ?? ""
        let time = message.time ?? 0
        let appeardText = appeard ? "appeared" : "disappeared"
        let detailedText = "id: \(messageId) uniqueId: \(uniqueId) message: \(text) time: \(time)"
        if isUp != nil {
            log("On message \(appeardText) when scrolling \(dir), \(detailedText)")
        } else {
            log("On message \(appeardText) with \(detailedText)")
        }
        Logger.viewModels.info("\(detailedText)")
#endif
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}