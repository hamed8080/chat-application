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
    public var userToCreateThread: Participant?
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
    public var lifeCycleState: AppLifeCycleState?
    public var objectsContainer: ObjectsContainer!
    public var appStateNavigationModel: AppStateNavigationModel = .init()

    @Published public var connectionStatus: ConnectionStatus = .connecting {
        didSet {
            setConnectionStatus(connectionStatus)
        }
    }

    private init() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] value in
                self?.onThreadEvent(value)
            }
            .store(in: &cancelable)
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                self?.onParticipantsEvents(event)
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

        NotificationCenter.windowMode.post(name: .windowMode, object: windowMode)
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .threads(let response):
            onGetThreads(response)
        case .created(let response):
            onForwardCreateConversation(response)
            onCreated(response)
        case .deleted(let response):
            onDeleted(response)
        case .left(let response):
            onLeft(response)
        default:
            break
        }
    }

    func onCreated(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result, conversation.type == .selfThread {
            navViewModel?.append(thread: conversation)
        }
    }

    private func onDeleted(_ response: ChatResponse<Participant>) {
        if let index = navViewModel?.pathsTracking.firstIndex(where: { ($0 as? ThreadViewModel)?.threadId == response.subjectId }) {
            navViewModel?.popPathTrackingAt(at: index)
        }
    }

    private func onLeft(_ response: ChatResponse<User>) {
        let deletedUserId = response.result?.id
        let myId = AppState.shared.user?.id
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.subjectId})
        let threadVM = navViewModel?.threadStack.first(where: {$0.threadId == conversation?.id})
        let participant = threadVM?.participantsViewModel.participants.first(where: {$0.id == deletedUserId})

        if deletedUserId == myId {
            if let conversation = conversation {
                threadsVM.removeThread(conversation)
            }

            /// Remove the ThreadViewModel for cleaning the memory.
            if let index = navViewModel?.pathsTracking.firstIndex(where: { ($0 as? ThreadViewModel)?.threadId == response.subjectId }) {
                navViewModel?.popPathTrackingAt(at: index)
            }

            /// If I am in the detail view and press leave thread I should remove first DetailViewModel -> ThreadViewModel
            /// That is the reason why we call paths.removeLast() twice.
            if let index = navViewModel?.pathsTracking.firstIndex(where: { ($0 as? ThreadDetailViewModel)?.thread?.id == response.subjectId }) {
                navViewModel?.popPathTrackingAt(at: index)
                navViewModel?.popLastPath()
                navViewModel?.popLastPath()
            }
        } else {
            if let participant = participant {
                threadVM?.participantsViewModel.removeParticipant(participant)
            }
            conversation?.participantCount = (conversation?.participantCount ?? 0) - 1
            threadVM?.thread.participantCount = conversation?.participantCount
            threadVM?.animateObjectWillChange()
        }
    }

    private func onParticipantsEvents(_ event: ParticipantEventTypes) {
        switch event {
        case .add(let response):
            onAddParticipants(response)
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
        if RequestsManager.shared.contains(key: response.uniqueId ?? ""), let thraed = response.result?.first {
            showThread(thread: thraed)
        }

        if !response.cache, (response.pop(prepend: "SEARCH-P2P") as? ThreadsRequest) != nil {
            onSearchP2PThreads(thread: response.result?.first)
        }

        if !response.cache, (response.pop(prepend: "SEARCH-GROUP-THREAD") as? ThreadsRequest) != nil {
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
        let userId = contact.user?.id ?? contact.user?.coreUserId ?? -1
        appStateNavigationModel.userToCreateThread = .init(contactId: contact.id,
                                                           id: userId,
                                                           image: contact.image ?? contact.user?.image,
                                                           name: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
        searchForP2PThread(coreUserId: userId)
    }

    public func openThread(participant: Participant) {
        appStateNavigationModel.userToCreateThread = participant
        searchForP2PThread(coreUserId: participant.coreUserId ?? -1)
    }

    public func openThreadWith(userName: String) {
        appStateNavigationModel.userToCreateThread = .init(username: userName)
        searchForP2PThread(coreUserId: nil, userName: userName)
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
        let messageIds = messages.sorted{$0.time ?? 0 < $1.time ?? 0}.compactMap{$0.id}
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
        guard !response.cache,
              let request = (response.pop(prepend: "FORWARD-CREATE-CONVERSATION") as? ForwardCreateConversationRequest),
              let conversation = response.result,
              let destinationConversationId = conversation.id
        else { return }
        navViewModel?.append(thread: conversation)
        /// We call send forward messages with a little bit of delay because it will get history in the above code and there should not be anything in the queue to forward messages.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: request.from, threadId: destinationConversationId, messageIds: request.messageIds)
        }
    }

    public func searchForP2PThread(coreUserId: Int?, userName: String? = nil) {
        if let thread = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            onSearchP2PThreads(thread: thread)
            return
        }
        let req = ThreadsRequest(type: .normal, partnerCoreUserId: coreUserId, userName: userName)
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
        objectsContainer.threadsVM.threads
            .first(where: {
                ($0.partner == coreUserId || ($0.participants?.contains(where: {$0.coreUserId == coreUserId}) ?? false))
                && $0.group == false && $0.type == .normal}
            )
    }

    public func checkForGroupOffline(tharedId: Int) -> Conversation? {
        objectsContainer.threadsVM.threads
            .first(where: { $0.group == true && $0.id == tharedId })
    }

    public func showEmptyThread() {
        guard let participant = appStateNavigationModel.userToCreateThread else { return }
        withAnimation {
            let particpants = [participant]
            let conversation = Conversation(id: LocalId.emptyThread.rawValue,
                                            image: participant.image,
                                            title: participant.name,
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

    func onAddParticipants(_ response: ChatResponse<Conversation>) {
        let addedParticipants = response.result?.participants ?? []
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.result?.id})
        let threadVM = navViewModel?.threadStack.first(where: {$0.threadId == conversation?.id})
        conversation?.participantCount = response.result?.participantCount ?? (conversation?.participantCount ?? 0) + addedParticipants.count
        threadVM?.participantsViewModel.onAdded(addedParticipants)
        threadVM?.animateObjectWillChange()
    }
}
