//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Foundation
import FanapPodChatSDK


let CONNECTION_STATUS_NAME        = "CONNECTION_STATUS_NAME"
let CONNECTION_STATUS_NAME_OBJECT = Notification.Name.init(CONNECTION_STATUS_NAME)

class ChatDelegateImplementation: ChatDelegates {
    
    //Sandbox
//    let socketAddresss = "wss://chat-sandbox.pod.ir/ws"
//    let serverName     = "chat-server"
//    let ssoHost        = "https://accounts.pod.ir"
//    let platformHost   = "https://sandbox.pod.ir:8043/srv/basic-platform"
//    let fileServer     = "http://sandbox.fanapium.com:8080"
    
    //Integration
//    let socketAddresss   =  "ws://172.16.110.235:8003/ws" // {*REQUIRED*} Socket Address
//    let ssoHost          =  "http://172.16.110.76" // {*REQUIRED*} Socket Address
//    let platformHost     =  "http://172.16.110.235:8003/srv/bptest-core"
//    let fileServer       =  "http://172.16.110.76:8080" // {*REQUIRED*} File Server Address
//    let serverName       =  "chatlocal" // {*REQUIRED*} Server to to
    
    //    let socketAddress           = "ws://172.16.110.235:8003/ws"
    //    let ssoHost                 = "http://172.16.110.76"
    //    let platformHost            = "http://172.16.110.235:8003/srv/bptest-core"
    //    let fileServer              = "http://172.16.110.76:8080"
    //    let serverName              = "chatlocal"

    //Main0
    let socketAddresss = "wss://msg.pod.ir/ws"
    let serverName     = "chat-server"
    let ssoHost        = "https://accounts.pod.ir"
    let platformHost   = "https://api.pod.ir/srv/core"
    let fileServer     = "https://core.pod.ir"
    
	private (set) static var sharedInstance = ChatDelegateImplementation()
    
    func createChatObject(){
		let token = UserDefaults.standard.string(forKey: "token")
		print("token is: \(token ?? "")")
		Chat.sharedInstance.createChatObject(config: .init(socketAddress: socketAddresss,
														   serverName: serverName,
														   token: "5d40718a5ea042af90f741a56cb61e33" ?? "3dd6895c8dc64f93bcd43b58dcc2aab3",
														   ssoHost: ssoHost,
														   platformHost: platformHost,
														   fileServer: fileServer,
                                                           enableCache: true,
                                                           msgTTL: 800000,//for integeration server need to be long time
														   reconnectOnClose: true,
                                                           isDebuggingLogEnabled: true,
                                                           enableNotificationLogObserver: true
                                                           
                                                        
		))
		
//        Chat.sharedInstance.createChatObject(socketAddress:             "String",
//                                             ssoHost:                   "String",
//                                             platformHost:              "String",
//                                             fileServer:                "String",
//                                             serverName:                "String",
//                                             token:                     "String",
//                                             mapApiKey:                 "String",
//                                             mapServer:                 "String",
//                                             typeCode:                  "String",
//                                             enableCache:               false,
//                                             cacheTimeStampInSec:       nil,
//                                             msgPriority:               nil,
//                                             msgTTL:                    nil,
//                                             httpRequestTimeout:        nil,
//                                             actualTimingLog:           nil,
//                                             wsConnectionWaitTime:      0,
//                                             connectionRetryInterval:   0,
//                                             connectionCheckTimeout:    0,
//                                             messageTtl:                0,
//                                             getDeviceIdFromToken:      false,
//                                             captureLogsOnSentry:       false,
//                                             maxReconnectTimeInterval:  0,
//                                             reconnectOnClose:          false,
//                                             localImageCustomPath:      nil,
//                                             localFileCustomPath:       nil,
//                                             deviecLimitationSpaceMB:   nil,
//                                             showDebuggingLogLevel:     nil)
		Chat.sharedInstance.delegate = self
    }
	
	func chatConnect() {
        print("🟡 chat connected")
        NotificationCenter.default.post(name: CONNECTION_STATUS_NAME_OBJECT ,object: "Connecting ...")
	}
	
	func chatDisconnect() {
        print("🔴 chat Disconnect")
        NotificationCenter.default.post(name: CONNECTION_STATUS_NAME_OBJECT ,object: "Disconnected")
	}
	
	func chatReconnect() {
		print("🔄 chat Reconnect")
        NotificationCenter.default.post(name: CONNECTION_STATUS_NAME_OBJECT ,object: "Reconnecting ...")
	}
	
	func chatReady(withUserInfo: User) {
        print("🟢 chat ready Called\(withUserInfo)")
        NotificationCenter.default.post(name: CONNECTION_STATUS_NAME_OBJECT ,object: "")
	}
	
	func chatState(state: AsyncStateType) {
		print("chat state changed: \(state)")
	}
	
	func chatError(errorCode: Int, errorMessage: String, errorResult: Any?) {
		if errorCode == 21  || errorCode == 401{
            NotificationCenter.default.post(name: CONNECTION_STATUS_NAME_OBJECT ,object: "Un Authorized!!!")
//            let st = UIStoryboard(name: "Main", bundle: nil)
//            let vc = st.instantiateViewController(identifier: "UpdateTokenController")
//            guard let rootVC = SceneDelegate.getRootViewController() else {return}
//            rootVC.presentedViewController?.dismiss(animated: true)
//            rootVC.present(vc, animated: true)
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
	}
	
	func systemEvents(model: SystemEventModel) {
		print(model)
	}
	
	func threadEvents(model: ThreadEventModel) {
		print(model)
	}
	
	func userEvents(model: UserEventModel) {
		print(model)
	}
}
