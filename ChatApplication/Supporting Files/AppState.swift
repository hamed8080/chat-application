//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import FanapPodChatSDK
import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    var user: User?
    var selectedThread: Conversation?
    var cache: CacheFactory? { ChatManager.activeInstance.cache }
    var cacheFileManager: CacheFileManagerProtocol? { ChatManager.activeInstance.cacheFileManager }
    @Published var callLogs: [URL]?
    @Published var connectionStatusString = ""
    @Published var showThreadView = false
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

    private init() {}

    // get cahe user from databse for working fast with something like showing message rows
    func setCachedUser() {
        cache?.get(cacheType: .userInfo) { (response: ChatResponse<User>) in
            self.user = response.result
        }
    }
}
