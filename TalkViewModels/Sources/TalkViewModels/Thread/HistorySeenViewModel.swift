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

public final class HistorySeenViewModel: ObservableObject {
    private weak var threadVM: ThreadViewModel?
    private var historyVM: ThreadHistoryViewModel? { threadVM?.historyVM }
    private var onScreenMessages: [Message] = []
    private var isFirstTimeProgramaticallyScroll: Bool = true
    private var seenPublisher = PassthroughSubject<Message, Never>()
    private var cancelable: Set<AnyCancellable> = []
    private var thread: Conversation? { threadVM?.thread }
    private let queue = DispatchQueue(label: "SEEN_SERIAL_QUEUE")

    public init(threadViewModel: ThreadViewModel) {
        self.threadVM = threadViewModel
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.queue.sync { [weak self] in
                self?.isFirstTimeProgramaticallyScroll = false
                self?.sendSeenAndReduceUnredaCountLocally()
            }
        }
        seenPublisher
            .filter{ [weak self] in $0.id ?? -1 >= self?.thread?.lastSeenMessageId ?? 0 }
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.sendSeen(for: newValue)
            }
            .store(in: &cancelable)
    }

    internal func onAppear(_ message: Message) {
        queue.sync {
            /// We get next item in the list because when we are scrolling up the message is beneth NavigationView so we should get the next item to ensure we are in right position
            guard
                let historyVM = historyVM,
                let sectionIndex = historyVM.sectionIndexByMessageId(message),
                let messageIndex = historyVM.messageIndex(message.id ?? -1, in: sectionIndex)
            else { return }

            let section = historyVM.sections[sectionIndex]
            let isScrollUP = threadVM?.scrollVM.scrollingUP == true
            let vms = section.vms
            let indices = vms.indices
            let hasUpMessage = indices.contains(messageIndex - 1) == true
            let hasDownMessage = vms.indices.contains(messageIndex + 1)

            if isScrollUP, hasUpMessage {
                let prevMessage = vms[messageIndex - 1].message
                onMessageScroll(prevMessage, isUp: true)
            } else if !isScrollUP, hasDownMessage, vms.first?.id != message.id {
                let nextMessage = vms[messageIndex + 1].message
                onMessageScroll(nextMessage, isUp: false)
            } else {
                // Last Item
                onMessageScroll(message)
            }
        }
    }

    internal func onDisappear(_ message: Message) {
        queue.sync {
            logMessageApperance(message, appeard: false)
            onScreenMessages.removeAll(where: {$0.id == message.id})
        }
    }

    private func sendSeenAndReduceUnredaCountLocally() {
        let maxId = onScreenMessages.compactMap({$0.id}).max()
        let message = onScreenMessages.first(where: {$0.id == maxId})
        guard let message else { return }
        reduceUnreadCountLocaly(message)
        seenPublisher.send(message)
    }

    private func onMessageScroll(_ message: Message, isUp: Bool? = nil) {
        logMessageApperance(message, appeard: true, isUp: isUp)
        onScreenMessages.append(message)
        if isFirstTimeProgramaticallyScroll == true {
            return
        }
        sendSeenAndReduceUnredaCountLocally()
    }

    /// We reduce it locally to keep the UI Sync and user feels it really read the message.
    /// However, we only send seen request with debouncing
    private func reduceUnreadCountLocaly(_ message: Message?) {
        guard 
            let threadVM = threadVM,
            let threadsVM = threadVM.threadsViewModel
        else { return }
        let thread = threadVM.thread
        let messageId = message?.id ?? -1
        let beforeUnreadCount = thread.unreadCount ?? -1
        let threadId = thread.id ?? 0
        if beforeUnreadCount > 0, messageId > thread.lastSeenMessageId ?? 0 {
            let newUnreadCount = beforeUnreadCount - 1
            thread.unreadCount = newUnreadCount
            if let index = threadsVM.threads.firstIndex(where: {$0.id == threadId}) {
                threadsVM.threads[index].unreadCount = newUnreadCount
            }
            threadsVM.animateObjectWillChange()
            animateObjectWillChange()
        }

        /// We do this to remove number 1 as fast as the user scrolls to the last Message in the thread
        /// If we remove these lines it will work, however, we should wait for the server's response to remove the number 1 unread count when the user scrolls fast.
        if thread.unreadCount == 1, messageId == thread.lastMessageVO?.id {
            if let index = threadsVM.threads.firstIndex(where: {$0.id == threadId}) {
                threadsVM.threads[index].unreadCount = 0
                threadsVM.animateObjectWillChange()
            }
            threadVM.animateObjectWillChange()
        }
    }

    private func sendSeen(for message: Message) {
        guard let thread = thread, let threadId = thread.id else { return }
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if let messageId = message.id, let lastMsgId = thread.lastSeenMessageId, messageId > lastMsgId, !isMe {
            thread.lastSeenMessageId = messageId
            log("send seen for message:\(message.messageTitle) with id:\(messageId)")
            ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
        }
    }

    internal func sendSeenForAllUnreadMessages() {
        if let message = thread?.lastMessageVO,
           message.seen == nil || message.seen == false,
           message.participant?.id != AppState.shared.user?.id,
           thread?.unreadCount ?? 0 > 0
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
