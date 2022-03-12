//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Foundation
import FanapPodChatSDK
import UIKit

enum ConnectionStatus:Int{
    case Connecting   = 0
    case Disconnected = 1
    case Reconnecting = 2
    case UnAuthorized = 3
    case CONNECTED    = 4
}

let CONNECT_NAME = Notification.Name("NotificationIdentifier")
let MESSAGE_NOTIFICATION_NAME = Notification.Name("MESSAGE_NOTIFICATION_NAME")
let SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME = Notification.Name("SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME")


class ChatDelegateImplementation: NewChatDelegate {

	private (set) static var sharedInstance = ChatDelegateImplementation()
    
    func createChatObject(){
        if let config = Config.getConfig(.Main){
            if config.server == "Integeration"{
                TokenManager.shared.saveSSOToken(ssoToken: SSOTokenResponse.Result(accessToken: config.debugToken, expiresIn: Int.max, idToken: nil, refreshToken: nil, scope: nil, tokenType: nil))
            }
            let token = TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken ?? config.debugToken
            print("token is: \(token ?? "")")
            Chat.sharedInstance.createChatObject(config: .init(socketAddress: config.socketAddresss,
                                                               serverName: config.serverName,
                                                               token: token,
                                                               ssoHost: config.ssoHost,
                                                               platformHost: config.platformHost,
                                                               fileServer: config.fileServer,
                                                               enableCache: true,
                                                               msgTTL: 800000,//for integeration server need to be long time
                                                               reconnectCount:Int.max,
                                                               reconnectOnClose: true,
//                                                               showDebuggingLogLevel:.verbose,
                                                               isDebuggingLogEnabled: true,
                                                               isDebuggingAsyncEnable: false,
                                                               enableNotificationLogObserver: true,
                                                               useNewSDK:true
            ))
            Chat.sharedInstance.delegate = self
        }
    }
	
	func chatState(state: AsyncStateType) {
		print("chat state changed: \(state)")
	}
	
	func chatError(errorCode: Int, errorMessage: String, errorResult: Any?) {
		if errorCode == 21  || errorCode == 401{
            TokenManager.shared.getNewTokenWithRefreshToken()
            AppState.shared.connectionStatus = .UnAuthorized
		}
	}
	
	func botEvents(model: BotEventModel) {
		print(model)
	}
	
	func contactEvents(model: ContactEventModel) {
		print(model)
	}
	
	func fileUploadEvents(model: FileUploadEventModel) {
		print(model)
	}
	
	func messageEvents(model: MessageEventModel) {
		print(model)
        NotificationCenter.default.post(name: MESSAGE_NOTIFICATION_NAME, object: model)
	}
	
	func systemEvents(model: SystemEventModel) {
		print(model)
        NotificationCenter.default.post(name: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME, object: model)
	}
	
	func threadEvents(model: ThreadEventModel) {
		print(model)
	}
	
	func userEvents(model: UserEventModel) {
		print(model)
	}
    
    func chatState(state: ChatState, currentUser: User?, error: ChatError?) {
        switch state {
        case .CONNECTING:
            print("🔄 chat connecting")
            AppState.shared.connectionStatus = .Connecting
        case .CONNECTED:
            print("🟡 chat connected")
            AppState.shared.connectionStatus = .Connecting
        case .CLOSED:
            print("🔴 chat Disconnect")
            AppState.shared.connectionStatus = .Disconnected
        case .ASYNC_READY:
            print("🟡 Async ready")
        case .CHAT_READY:
            print("🟢 chat ready Called\(String(describing: currentUser))")
            AppState.shared.connectionStatus = .CONNECTED
            NotificationCenter.default.post(name: CONNECT_NAME, object: nil)
        }
    }
    
    func chatError(error: ChatError) {
        
    }
    
    func chatConnect() {
        
    }
    
    func chatDisconnect() {
        
    }
    
    func chatReconnect() {
        
    }
    
    func chatReady(withUserInfo: User) {
        
    }
}
