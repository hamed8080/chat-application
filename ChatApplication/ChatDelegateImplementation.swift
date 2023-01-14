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
let callEventName = Notification.Name("callEventName")

class ChatDelegateImplementation: ChatDelegate {
    private(set) static var sharedInstance = ChatDelegateImplementation()

    func createChatObject() {
        if let config = Config.getConfig(.sandbox) {
            if config.server == "Integeration" {
                TokenManager.shared.saveSSOToken(ssoToken: SSOTokenResponseResult(accessToken: config.debugToken, expiresIn: Int.max))
            }
            TokenManager.shared.initSetIsLogin()
            let asyncConfig = AsyncConfigBuilder()
                .socketAddress(config.socketAddresss)
                .reconnectCount(Int.max)
                .reconnectOnClose(true)
                .appId("PodChat")
                .serverName(config.serverName)
                .isDebuggingLogEnabled(false)
                .build()
            let chatConfig = ChatConfigBuilder(asyncConfig)
                .token(TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken ?? config.debugToken ?? "")
                .ssoHost(config.ssoHost)
                .platformHost(config.platformHost)
                .fileServer(config.fileServer)
                .enableCache(true)
                .msgTTL(800_000) // for integeration server need to be long time
                .isDebuggingLogEnabled(true)
                .callTimeout(20)
                .persistLogsOnServer(true)
                .appGroup(AppGroup.group)
                .sendLogInterval(15)
                .build()
            ChatManager.instance.createInstance(config: chatConfig)
            ChatManager.activeInstance.delegate = self
            if let token = TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken ?? config.debugToken {
                print("token is: \(token)")
                ChatManager.activeInstance.connect()
            }
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
            UserDefaults.standard.setValue(codable: ChatManager.activeInstance.userInfo, forKey: "USER")
        case .uninitialized:
            print("Chat object is not initialized.")
        }
    }

    func chatError(error: ChatError) {
        if error.code == 21 || error.code == 401 {
            TokenManager.shared.getNewTokenWithRefreshToken()
            AppState.shared.connectionStatus = .unauthorized
        }
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

        if case let .call(event) = event {
            NotificationCenter.default.post(name: callEventName, object: event)
        }
    }
}
