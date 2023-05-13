//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Chat
import ChatAppModels
import ChatAppViewModels
import ChatCore
import ChatModels
import Foundation
import Logger
import UIKit

final class ChatDelegateImplementation: ChatDelegate {
    private(set) static var sharedInstance = ChatDelegateImplementation()

    func createChatObject() {
//        if let userConfig = UserConfigManagerVM.instance.currentUserConfig, let userId = userConfig.id {
//            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: userId, config: userConfig.config, delegate: self)
//            TokenManager.shared.initSetIsLogin()
//        }

        Task {
            let ssoToken = SSOTokenResponseResult(accessToken: "0128f6fae42b437d88d92b6d97a6e015.XzIwMjM1", expiresIn: 900)
            let config = Config.config(token: ssoToken.accessToken ?? "", selectedServerType: .main)
            let user = User(id: 3_463_768)
            TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
            UserConfigManagerVM.instance.appendOrReplace(UserConfig(user: user, config: config, ssoToken: ssoToken))
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: user.id, config: config, delegate: self)
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
            NotificationCenter.default.post(name: .connectName, object: nil)
        case .uninitialized:
            print("Chat object is not initialized.")
        }
    }

    func chatError(error: ChatError) {
        print(error)
        if error.code == 21 || error.code == 401 {
            TokenManager.shared.getNewTokenWithRefreshToken()
            AppState.shared.connectionStatus = .unauthorized
        } else {
            AppState.shared.animateAndShowError(error)
        }
    }

    func chatEvent(event: ChatEventType) {
        print(dump(event))
        switch event {
        case .bot:
            break
        case .contact:
            break
        case let .call(callEventTypes):
            NotificationCenter.default.post(name: .callEventName, object: callEventTypes)
        case .file:
            break
        case let .system(systemEventTypes):
            NotificationCenter.default.post(name: .systemMessageEventNotificationName, object: systemEventTypes)
        case let .message(messageEventTypes):
            NotificationCenter.default.post(name: .messageNotificationName, object: messageEventTypes)
        case let .thread(threadEventTypes):
            NotificationCenter.default.post(name: .threadEventNotificationName, object: threadEventTypes)
        case let .user(userEventTypes):
            if case let .onUser(response) = userEventTypes, let user = response.result {
                UserConfigManagerVM.instance.onUser(user)
            }
        case .assistant:
            break
        case .tag:
            break
        }
    }

    func onLog(log: Log) {
        NotificationCenter.default.post(name: .logsName, object: log)
        print(log.message ?? "", "\n")
    }
}
