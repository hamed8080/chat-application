//
//  AppState.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Chat
import SwiftUI
import TalkModels
import ChatModels
import TalkExtensions
import ChatCore
import Combine
import ChatDTO

public enum AppLifeCycleState {
    case foreground
    case background
    case inactive
    case active
}

struct ForwardCreateConversationRequest: ChatDTO.UniqueIdProtocol {
    let uniqueId: String
    let from: Int
    let messageIds: [Int]
    let request: CreateThreadRequest

    init(uniqueId: String, from: Int, messageIds: [Int], request: CreateThreadRequest) {
        self.uniqueId = uniqueId
        self.from = from
        self.messageIds = messageIds
        self.request = request
    }
}

/// Properties that can transfer between each navigation page and stay alive unless manually destroyed.
public struct AppStateNavigationModel {
    public var replyPrivately: Message?
    public var forwardMessages: [Message]?
    public var forwardMessageRequest: ForwardMessageRequest?
    public var moveToMessageId: Int?
    public var moveToMessageTime: UInt?
    public init() {}
}

public final class AppState: ObservableObject {
    public static let shared = AppState()
    public var cachedUser = UserConfigManagerVM.instance.currentUserConfig?.user
    public var user: User? { cachedUser ?? ChatManager.activeInstance?.userInfo }
    public var navViewModel: NavigationModel?
    @Published public var error: ChatError?
    @Published public var isLoading: Bool = false
    @Published public var callLogs: [URL]?
    @Published public var connectionStatusString = ""
    private var cancelable: Set<AnyCancellable> = []
    public var windowMode: WindowMode = .iPhone
    public static var isInSlimMode = AppState.shared.windowMode.isInSlimMode
    public var userToCreateThread: User?
    public var lifeCycleState: AppLifeCycleState?
    public var objectsContainer: ObjectsContainer!
    public var appStateNavigationModel: AppStateNavigationModel = .init()

    @Published public var connectionStatus: ConnectionStatus = .connecting {
        didSet {
            setConnectionStatus(connectionStatus)
        }
    }

    private init() {
        NotificationCenter.default.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        UIApplication.shared.connectedScenes.first(where: {$0.activationState == .foregroundActive}).publisher.sink { [weak self] newValue in
            self?.updateWindowMode()
        }
        .store(in: &cancelable)
        updateWindowMode()
    }

    public func updateWindowMode() {
        windowMode = UIApplication.shared.windowMode()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            AppState.isInSlimMode = UIApplication.shared.windowMode().isInSlimMode
        }

        NotificationCenter.default.post(name: .windowMode, object: windowMode)
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .threads(let response):
            onGetThreads(response)
        case .created(let response):
            onForwardCreateConversation(response)
        default:
            break
        }
    }

    public func setConnectionStatus(_ status: ConnectionStatus) {
        if status == .connected {
            connectionStatusString = ""
        } else {
            connectionStatusString = String(describing: status) + " ..."
        }
    }

    func onGetThreads(_ response: ChatResponse<[Conversation]>) {
        if response.value != nil, let thraed = response.result?.first {
            showThread(thread: thraed)
        }

        if (response.value(prepend: "SEARCH-P2P") as? ThreadsRequest) != nil, !response.cache {
            onSearchP2PThreads(thread: response.result?.first)
        }

        if (response.value(prepend: "SEARCH-GROUP-THREAD") as? ThreadsRequest) != nil, !response.cache {
            onSearchGroupThreads(thread: response.result?.first)
        }
    }

    public func showThread(thread: Conversation) {
        withAnimation {
            isLoading = false
            navViewModel?.append(thread: thread)
        }
    }

    public func openThread(contact: Contact) {
        userToCreateThread = .init(id: contact.user?.coreUserId, image: contact.image ?? contact.user?.image, name: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
        searchForP2PThread(coreUserId: contact.user?.coreUserId ?? -1)
    }

    public func openThread(participant: Participant) {
        userToCreateThread = .init(id: participant.coreUserId, image: participant.image, name: participant.name)
        searchForP2PThread(coreUserId: participant.coreUserId ?? -1)
    }

    public func openThread(user: User) {
        userToCreateThread = .init(id: user.coreUserId, image: user.image, name: user.name)
        searchForP2PThread(coreUserId: user.coreUserId ?? -1)
    }

    public func openThreadAndMoveToMessage(conversationId: Int, messageId: Int, messageTime: UInt) {
        self.appStateNavigationModel.moveToMessageId = messageId
        self.appStateNavigationModel.moveToMessageTime = messageTime
        searchForGroupThread(threadId: conversationId, moveToMessageId: messageId, moveToMessageTime: messageTime)
    }

    /// Forward messages form a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    public func openThread(from: Int, conversation: Conversation?, contact: Contact?, messages: [Message]) {
        self.appStateNavigationModel.forwardMessages = messages
        let messageIds = messages.compactMap{$0.id}
        if let conversation = conversation , let destinationConversationId = conversation.id {
            navViewModel?.append(thread: conversation)
            appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: from, threadId: destinationConversationId, messageIds: messageIds)
        } else if let coreUserId = contact?.user?.coreUserId, let conversation = checkForP2POffline(coreUserId: coreUserId), let destinationConversationId = conversation.id {
            navViewModel?.append(thread: conversation)
            appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: from, threadId: destinationConversationId, messageIds: messageIds)
        } else if let coreUserId = contact?.user?.coreUserId {
            openForwardConversation(coreUserId: coreUserId, fromThread: from, messageIds: messageIds)
        }
    }

    public func openForwardConversation(coreUserId: Int, fromThread: Int, messageIds: [Int]) {
        let invitees = [Invitee(id: "\(coreUserId)", idType: .coreUserId)]
        let req = CreateThreadRequest(invitees: invitees, title: "")
        let request = ForwardCreateConversationRequest(uniqueId: req.uniqueId, from: fromThread, messageIds: messageIds, request: req)
        RequestsManager.shared.append(prepend: "FORWARD-CREATE-CONVERSATION", value: request)
        ChatManager.activeInstance?.conversation.create(req)
    }

    private func onForwardCreateConversation(_ response: ChatResponse<Conversation>) {
        guard let request = (response.value(prepend: "FORWARD-CREATE-CONVERSATION") as? ForwardCreateConversationRequest),
              !response.cache,
              let conversation = response.result,
              let destinationConversationId = conversation.id
        else { return }
        navViewModel?.append(thread: conversation)
        /// We call send forward messages with a little bit of delay because it will get history in the above code and there should not be anything in the queue to forward messages.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: request.from, threadId: destinationConversationId, messageIds: request.messageIds)
        }
    }

    public func searchForP2PThread(coreUserId: Int) {
        if let thread = checkForP2POffline(coreUserId: coreUserId) {
            onSearchP2PThreads(thread: thread)
            return
        }
        let req = ThreadsRequest(type: .normal, partnerCoreUserId: coreUserId)
        RequestsManager.shared.append(prepend: "SEARCH-P2P", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func searchForGroupThread(threadId: Int, moveToMessageId: Int, moveToMessageTime: UInt) {
        if let thread = checkForGroupOffline(tharedId: threadId) {
            onSearchGroupThreads(thread: thread)
            return
        }
        let req = ThreadsRequest(threadIds: [threadId])
        RequestsManager.shared.append(prepend: "SEARCH-GROUP-THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func onSearchGroupThreads(thread: Conversation?) {
        if let thread = thread {
            navViewModel?.append(thread: thread)
        }
    }

    public func onSearchP2PThreads(thread: Conversation?) {
        if let thread = thread {
            navViewModel?.append(thread: thread)
        } else {
            showEmptyThread()
        }
    }

    public func checkForP2POffline(coreUserId: Int) -> Conversation? {
        navViewModel?.threadsViewModel?.threads
            .first(where: {
                ($0.partner == coreUserId || ($0.participants?.contains(where: {$0.coreUserId == coreUserId}) ?? false))
                && $0.group == false && $0.type == .normal}
            )
    }

    public func checkForGroupOffline(tharedId: Int) -> Conversation? {
        navViewModel?.threadsViewModel?.threads
            .first(where: { $0.group == true && $0.id == tharedId })
    }

    public func showEmptyThread() {
        guard let userToCreateThread else { return }
        withAnimation {
            let particpants = [Participant(coreUserId: userToCreateThread.id)]
            let conversation = Conversation(id: LocalId.emptyThread.rawValue,
                                            image: userToCreateThread.image,
                                            title: userToCreateThread.name,
                                            participants: particpants)
            navViewModel?.append(thread: conversation)
            isLoading = false
        }
    }

    public func animateAndShowError(_ error: ChatError) {
        withAnimation {
            isLoading = false
            self.error = error
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.error = nil
            }
        }
    }
}
