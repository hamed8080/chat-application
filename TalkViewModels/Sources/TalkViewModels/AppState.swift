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
    private var requests: [String: Any] = [:]
    public var windowMode: WindowMode = .iPhone
    public var userToCreateThread: User?
    public var replyPrivately: Message?

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
        NotificationCenter.default.post(name: .windowMode, object: windowMode)
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .threads(let response):
            onGetThreads(response)
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
        if let uniqueId = response.uniqueId, let thraed = response.result?.first, requests[uniqueId] != nil {
            showThread(thread: thraed)
            requests.removeValue(forKey: uniqueId)
        }

        if let uniqueId = response.uniqueId, requests["SEARCH_P2P_\(uniqueId)"] as? ThreadsRequest != nil, !response.cache {
            onSearchP2PThreads(thread: response.result?.first)
            requests.removeValue(forKey: "SEARCH_P2P_\(uniqueId)")
        }
    }

    public func showThread(thread: Conversation) {
        withAnimation {
            isLoading = false
            navViewModel?.selectedSideBarId = "Tab.chats"
            navViewModel?.selectedThreadId = thread.id
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

    public func searchForP2PThread(coreUserId: Int) {
        if let thread = checkForP2POffline(coreUserId: coreUserId) {
            onSearchP2PThreads(thread: thread)
            return
        }
        let req = ThreadsRequest(type: .normal, partnerCoreUserId: coreUserId)
        requests["SEARCH_P2P_\(req.uniqueId)"] = req
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func onSearchP2PThreads(thread: Conversation?) {
        if let thread = thread {
            navViewModel?.append(thread: thread)
        } else {
            showEmptyThread()
        }
    }

    public func checkForP2POffline(coreUserId: Int) -> Conversation? {
        navViewModel?.threadViewModel?.threads
            .first(where: {
                ($0.partner == coreUserId || ($0.participants?.contains(where: {$0.coreUserId == coreUserId}) ?? false))
                && $0.group == false && $0.type == .normal}
            )
    }

    public func showEmptyThread() {
        guard let userToCreateThread else { return }
        withAnimation {
            navViewModel?.append(thread: .init(id: LocalId.emptyThread.rawValue, image: userToCreateThread.image, title: userToCreateThread.name, participants: [.init(coreUserId: userToCreateThread.id)]))
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
