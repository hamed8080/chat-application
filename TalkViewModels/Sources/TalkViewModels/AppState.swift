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

/// Properties that can transfer between each navigation page and stay alive unless manually destroyed.
public struct AppStateNavigationModel {
    public var userToCreateThread: Participant?
    public var replyPrivately: Message?
    public var forwardMessages: [Message]?
    public var forwardMessageRequest: ForwardMessageRequest?
    public var moveToMessageId: Int?
    public var moveToMessageTime: UInt?
    public var openURL: URL?
    public init() {}
}

public final class AppState: ObservableObject {
    public static let shared = AppState()
    private var cachedUser: User? { UserConfigManagerVM.instance.currentUserConfig?.user }
    public var user: User? { cachedUser ?? ChatManager.activeInstance?.userInfo }
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
        registerObservers()
        updateWindowMode()
    }

    public func updateWindowMode() {
        windowMode = UIApplication.shared.windowMode()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            AppState.isInSlimMode = UIApplication.shared.windowMode().isInSlimMode
        }

        NotificationCenter.windowMode.post(name: .windowMode, object: windowMode)
    }

    public func setConnectionStatus(_ status: ConnectionStatus) {
        if status == .connected {
            connectionStatusString = ""
        } else {
            connectionStatusString = String(describing: status) + " ..."
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

// Observers.
private extension AppState {
    private func registerObservers() {
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
    }
}

// Event handlers.
private extension AppState {
    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .threads(let response):
            onGetThreads(response)
        case .created(let response):
            onCreated(response)
        case .deleted(let response):
            onDeleted(response)
        case .left(let response):
            onLeft(response)
        default:
            break
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
}

// Conversation
public extension AppState {
    private func onGetThreads(_ response: ChatResponse<[Conversation]>) {
        if RequestsManager.shared.contains(key: response.uniqueId ?? ""), let thraed = response.result?.first {
            showThread(thread: thraed)
        }

        if !response.cache, let req = (response.pop(prepend: "SEARCH-P2P") as? ThreadsRequest) {
            onSearchP2PThreads(thread: response.result?.first, request: req)
        }

        if !response.cache, (response.pop(prepend: "SEARCH-GROUP-THREAD") as? ThreadsRequest) != nil {
            onSearchGroupThreads(thread: response.result?.first)
        }
    }

    private func onCreated(_ response: ChatResponse<Conversation>) {
        if !response.cache, response.pop(prepend: "CREATE-SELF-THREAD") != nil, let conversation = response.result, conversation.type == .selfThread {
            objectsContainer.navVM.append(thread: conversation)
        }
    }

    private func onDeleted(_ response: ChatResponse<Participant>) {
        if let index = objectsContainer.navVM.pathsTracking.firstIndex(where: { ($0 as? ThreadViewModel)?.threadId == response.subjectId }) {
            objectsContainer.navVM.popPathTrackingAt(at: index)
        }
    }

    private func onLeft(_ response: ChatResponse<User>) {
        let deletedUserId = response.result?.id
        let myId = AppState.shared.user?.id
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.subjectId})
        let threadVM = objectsContainer.navVM.viewModel(for: conversation?.id ?? -1)
        let participant = threadVM?.participantsViewModel.participants.first(where: {$0.id == deletedUserId})

        if deletedUserId == myId {
            if let conversation = conversation {
                threadsVM.removeThread(conversation)
            }

            /// If I am in the detail view and press leave thread I should remove first DetailViewModel -> ThreadViewModel
            if objectsContainer.navVM.pathsTracking.firstIndex(where: { ($0 as? ConversationDetailNavigationValue)?.viewModel.thread?.id == response.subjectId }) != nil {
                objectsContainer.navVM.popLastPath()
            }

            /// Remove Thread View model and pop ThreadView
            if let index = objectsContainer.navVM.pathsTracking.firstIndex(where: { ($0 as? ConversationNavigationValue)?.viewModel.threadId == response.subjectId }) {
                objectsContainer.navVM.popLastPath()
                objectsContainer.navVM.popPathTrackingAt(at: index)
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

    func showThread(thread: Conversation, created: Bool = false) {
        withAnimation {
            isLoading = false
            objectsContainer.navVM.append(thread: thread, created: created)
        }
    }

    func openThread(contact: Contact) {
        let userId = contact.user?.id ?? contact.user?.coreUserId ?? -1
        appStateNavigationModel.userToCreateThread = .init(contactId: contact.id,
                                                           id: userId,
                                                           image: contact.image ?? contact.user?.image,
                                                           name: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
        searchForP2PThread(coreUserId: userId)
    }

    func openThread(participant: Participant) {
        appStateNavigationModel.userToCreateThread = participant
        searchForP2PThread(coreUserId: participant.coreUserId ?? -1)
    }

    func openThreadWith(userName: String) {
        appStateNavigationModel.userToCreateThread = .init(username: userName)
        searchForP2PThread(coreUserId: nil, userName: userName)
    }

    func openSelfThread() {
        let req = CreateThreadRequest(title: String(localized: .init("Thread.selfThread"), bundle: Language.preferedBundle), type: StrictThreadTypeCreation.selfThread.threadType)
        RequestsManager.shared.append(prepend: "CREATE-SELF-THREAD", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    /// Forward messages form a thread to a destination thread.
    /// If the conversation is nil it try to use contact. Firstly it opens a conversation using the given contact core user id then send messages to the conversation.
    func openThread(from: Int, conversation: Conversation?, contact: Contact?, messages: [Message]) {
        self.appStateNavigationModel.forwardMessages = messages
        let messageIds = messages.sorted{$0.time ?? 0 < $1.time ?? 0}.compactMap{$0.id}
        if let conversation = conversation , let destinationConversationId = conversation.id {
            objectsContainer.navVM.append(thread: conversation)
            appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: from, threadId: destinationConversationId, messageIds: messageIds)
        } else if let coreUserId = contact?.user?.coreUserId, let conversation = checkForP2POffline(coreUserId: coreUserId), let destinationConversationId = conversation.id {
            objectsContainer.navVM.append(thread: conversation)
            appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: from, threadId: destinationConversationId, messageIds: messageIds)
        } else if let coreUserId = contact?.user?.coreUserId {
            // Empty conversation
            let dstId = LocalId.emptyThread.rawValue
            appStateNavigationModel.userToCreateThread = .init(coreUserId: coreUserId, id: coreUserId)
            appStateNavigationModel.forwardMessageRequest = ForwardMessageRequest(fromThreadId: from, threadId: dstId, messageIds: messageIds)
            let title = "\(contact?.firstName ?? "") \(contact?.lastName ?? "")"
            let conversation = Conversation(id: dstId, image: contact?.image ?? contact?.user?.image, title: title)
            objectsContainer.navVM.append(thread: conversation)
        }
    }

    func searchForP2PThread(coreUserId: Int?, userName: String? = nil) {
        if let thread = checkForP2POffline(coreUserId: coreUserId ?? -1) {
            onSearchP2PThreads(thread: thread)
            return
        }
        let req = ThreadsRequest(type: .normal, partnerCoreUserId: coreUserId, userName: userName)
        RequestsManager.shared.append(prepend: "SEARCH-P2P", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    func searchForGroupThread(threadId: Int, moveToMessageId: Int, moveToMessageTime: UInt) {
        if let thread = checkForGroupOffline(tharedId: threadId) {
            onSearchGroupThreads(thread: thread)
            return
        }
        let req = ThreadsRequest(threadIds: [threadId])
        RequestsManager.shared.append(prepend: "SEARCH-GROUP-THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    private func onSearchGroupThreads(thread: Conversation?) {
        if let thread = thread {
            objectsContainer.navVM.append(thread: thread)
        }
    }

    private func onSearchP2PThreads(thread: Conversation?, request: ThreadsRequest? = nil) {
        let thread = getRefrenceObject(thread) ?? thread
        if let thread = thread {
            objectsContainer.navVM.append(thread: thread)
        } else {
            showEmptyThread(userName: request?.userName)
        }
    }

    func checkForP2POffline(coreUserId: Int) -> Conversation? {
        objectsContainer.threadsVM.threads
            .first(where: {
                ($0.partner == coreUserId || ($0.participants?.contains(where: {$0.coreUserId == coreUserId}) ?? false))
                && $0.group == false && $0.type == .normal}
            )
    }

    /// It will search through the Conversation array to prevent creation of new refrence.
    /// If we don't use object refrence in places that needs to open the thread there will be a inconsistensy in data such as reply privately.
    private func getRefrenceObject(_ conversation: Conversation?) -> Conversation? {
        objectsContainer.threadsVM.threads.first{ $0.id == conversation?.id}
    }

    func checkForGroupOffline(tharedId: Int) -> Conversation? {
        objectsContainer.threadsVM.threads
            .first(where: { $0.group == true && $0.id == tharedId })
    }

    func showEmptyThread(userName: String? = nil) {
        guard let participant = appStateNavigationModel.userToCreateThread else { return }
        withAnimation {
            let particpants = [participant]
            let conversation = Conversation(id: LocalId.emptyThread.rawValue,
                                            image: participant.image,
                                            title: participant.name ?? userName,
                                            participants: particpants)
            objectsContainer.navVM.append(thread: conversation)
            isLoading = false
        }
    }

    func openThreadAndMoveToMessage(conversationId: Int, messageId: Int, messageTime: UInt) {
        self.appStateNavigationModel.moveToMessageId = messageId
        self.appStateNavigationModel.moveToMessageTime = messageTime
        searchForGroupThread(threadId: conversationId, moveToMessageId: messageId, moveToMessageTime: messageTime)
    }
}

// Participant
public extension AppState {
    private func onAddParticipants(_ response: ChatResponse<Conversation>) {
        let addedParticipants = response.result?.participants ?? []
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.result?.id})
        let threadVM = objectsContainer.navVM.viewModel(for: conversation?.id ?? -1)
        conversation?.participantCount = response.result?.participantCount ?? (conversation?.participantCount ?? 0) + addedParticipants.count
        threadVM?.participantsViewModel.onAdded(addedParticipants)
        threadVM?.animateObjectWillChange()
    }
}


public extension AppState {
    func openURL(url: URL) {
        appStateNavigationModel.openURL = url
        animateObjectWillChange()
    }
}

public extension AppState {
    func clear() {
        appStateNavigationModel = .init()
        callLogs = nil
        error = nil
        isLoading = false
    }
}

// Lifesycle
public extension AppState {
    var isInForeground: Bool { lifeCycleState == .active || lifeCycleState == .foreground }
}
