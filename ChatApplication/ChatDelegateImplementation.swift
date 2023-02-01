//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import FanapPodAsyncSDK
import FanapPodChatSDK
import Foundation
import UIKit

enum ConnectionStatus: Int {
    case connecting = 0
    case disconnected = 1
    case reconnecting = 2
    case unauthorized = 3
    case connected = 4

    var stringValue: String {
        switch self {
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnected: return "disconnected"
        case .reconnecting: return "reconnectiong"
        case .unauthorized: return "un authorized"
        }
    }
}

let fileDeletedFromCacheName = Notification.Name("fileDeletedFromCacheName")
let connectName = Notification.Name("connectName")
let messageNotificationName = Notification.Name("messageNotificationName")
let systemMessageEventNotificationName = Notification.Name("systemMessageEventNotificationName")
let threadEventNotificationName = Notification.Name("threadEventNotificationName")

class ChatDelegateImplementation: ChatDelegate {
    private(set) static var sharedInstance = ChatDelegateImplementation()

    func createChatObject() {
        if let userConfig = UserConfigManager.currentUserConfig, let userId = userConfig.id {
            UserConfigManager.createChatObjectAndConnect(userId: userId, config: userConfig.config)
            TokenManager.shared.initSetIsLogin()
        }
    }

    func chatState(state: ChatState, currentUser: User?, error _: ChatError?) {
        switch state {
        case .connecting:
            print("🔄 chat connecting")
            AppState.shared.connectionStatus = .connecting
        case .connected:
            print("🟡 chat connected")
            AppState.shared.connectionStatus = .connecting
        case .closed:
            print("🔴 chat Disconnect")
            AppState.shared.connectionStatus = .disconnected
        case .asyncReady:
            print("🟡 Async ready")
        case .chatReady:
            print("🟢 chat ready Called\(String(describing: currentUser))")
            AppState.shared.connectionStatus = .connected
            NotificationCenter.default.post(name: connectName, object: nil)
        case .uninitialized:
            print("Chat object is not initialized.")
        }
    }

    func chatError(error: ChatError) {
        if error.code == 21 || error.code == 401 {
            Task {
                await TokenManager.shared.getNewTokenWithRefreshToken()
            }
            AppState.shared.connectionStatus = .unauthorized
        }
        AppState.shared.animateAndShowError(error)
        print(error)
    }

    func chatEvent(event: ChatEventType) {
        print(event)
        if case let .system(event) = event {
            NotificationCenter.default.post(name: systemMessageEventNotificationName, object: event)
        }

        if case let .thread(event) = event {
            NotificationCenter.default.post(name: threadEventNotificationName, object: event)
        }

        if case let .message(event) = event {
            NotificationCenter.default.post(name: messageNotificationName, object: event)
        }

        if case let .file(event) = event {
            print("file Event:\(dump(event))")
        }

        if case let .user(eventUser) = event, case let .onUser(response) = eventUser, let user = response.result {
            UserConfigManager.onUser(user)
        }
    }
}
