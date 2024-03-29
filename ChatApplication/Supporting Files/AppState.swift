//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Chat
import SwiftUI

final class AppState: ObservableObject {
    static let shared = AppState()
    var cachedUser = UserConfigManagerVM.instance.currentUserConfig?.user
    var user: User? { cachedUser ?? ChatManager.activeInstance?.userInfo }
    var navViewModel: NavigationModel?
    @Published var error: ChatError?
    @Published var isLoading: Bool = false
    var cacheFileManager: CacheFileManagerProtocol? { ChatManager.activeInstance?.cacheFileManager }
    @Published var callLogs: [URL]?
    @Published var connectionStatusString = ""
    var activeThreadId: Int?
    @Published var connectionStatus: ConnectionStatus = .connecting {
        didSet {
            setConnectionStatus(connectionStatus)
        }
    }

    func setConnectionStatus(_ status: ConnectionStatus) {
        if status == .connected {
            connectionStatusString = ""
        } else {
            connectionStatusString = String(describing: status) + " ..."
        }
    }

    func showThread(threadId: Int) {
        isLoading = true
        activeThreadId = threadId
        ChatManager.activeInstance?.getThreads(.init(threadIds: [threadId])) { [weak self] response in
            if let thraed = response.result?.first {
                self?.animateAndShowThread(thread: thraed)
            }
        }
    }

    func showThread(invitees: [Invitee]) {
        isLoading = true
        ChatManager.activeInstance?.createThread(.init(invitees: invitees, title: "", type: .normal)) { [weak self] response in
            if let thread = response.result {
                self?.animateAndShowThread(thread: thread)
                self?.activeThreadId = thread.id
            } else if let error = response.error {
                self?.animateAndShowError(error)
            }
        }
    }

    func showThread(userName: String) {
        let invitees: [Invitee] = [.init(id: userName, idType: .username)]
        showThread(invitees: invitees)
    }

    func animateAndShowThread(thread: Conversation) {
        withAnimation {
            isLoading = false
            navViewModel?.selectedSideBarId = "chats"
            navViewModel?.selectedThreadId = thread.id
        }
    }

    func animateAndShowError(_ error: ChatError) {
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
