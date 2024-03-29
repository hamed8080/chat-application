//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Async
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
        if let userConfig = UserConfigManagerVM.instance.currentUserConfig, let userId = userConfig.id {
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: userId, config: userConfig.config, delegate: self)
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
