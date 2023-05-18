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
    @Published public var connectionStatus: ConnectionStatus = .connecting {
        didSet {
            setConnectionStatus(connectionStatus)
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
        ChatManager.activeInstance?.getThreads(.init(threadIds: [threadId])) { [weak self] response in
            if let thraed = response.result?.first {
                self?.showThread(thread: thraed)
            }
        }
    }

    public func showThread(invitees: [Invitee]) {
        isLoading = true
        ChatManager.activeInstance?.createThread(.init(invitees: invitees, title: "", type: .normal)) { [weak self] response in
            if let thread = response.result {
                self?.showThread(thread: thread)
                self?.activeThreadId = thread.id
            } else if let error = response.error {
                self?.animateAndShowError(error)
            }
        }
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

    private init() {}
}
