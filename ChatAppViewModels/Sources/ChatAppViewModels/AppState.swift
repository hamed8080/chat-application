//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Chat
import SwiftUI
import ChatAppModels
import ChatModels
import ChatAppExtensions
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
    public var activeThreadId: Int?
    private var cancelable: Set<AnyCancellable> = []
    private var requests: [String: Any] = [:]
    public var windowMode: WindowMode = .iPhone

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
        case .created(let response):
            onCreateThread(response)
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

    public func showThread(threadId: Int) {
        isLoading = true
        activeThreadId = threadId
        ChatManager.activeInstance?.conversation.get(.init(threadIds: [threadId]))
    }

    func onGetThreads(_ response: ChatResponse<[Conversation]>) {
        if let uniqueId = response.uniqueId, let thraed = response.result?.first, requests[uniqueId] != nil {
            showThread(thread: thraed)
            requests.removeValue(forKey: uniqueId)
        }
    }

    func onCreateThread(_ response: ChatResponse<Conversation>) {
        if let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            if let thread = response.result {
                showThread(thread: thread)
                activeThreadId = thread.id
            } else if let error = response.error {
                animateAndShowError(error)
            }
            requests.removeValue(forKey: uniqueId)
        }
    }

    public func showThread(invitees: [Invitee]) {
        isLoading = true
        let req = CreateThreadRequest(invitees: invitees, title: "", type: .normal)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func showThread(userName: String) {
        let invitees: [Invitee] = [.init(id: userName, idType: .username)]
        showThread(invitees: invitees)
    }

    public func showThread(thread: Conversation) {
        withAnimation {
            isLoading = false
            navViewModel?.selectedSideBarId = "Chats"
            navViewModel?.selectedThreadId = thread.id
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
