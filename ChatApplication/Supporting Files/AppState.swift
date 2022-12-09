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
        CacheFactory.get(useCache: true, cacheType: .userInfo) { response in
            self.user = response.cacheResponse as? User
        }
    }
}
