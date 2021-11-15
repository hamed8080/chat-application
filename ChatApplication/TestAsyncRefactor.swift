//
//  TestAsyncRefactor.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/25/21.
//

import SwiftUI
import FanapPodAsyncSDK
import FanapPodChatSDK
var async:NewAsync = NewAsync(config: AsyncConfig(socketAddress: Config.getConfig(.Sandbox)?.socketAddresss ?? "",
                                               serverName: Config.getConfig(.Sandbox)?.serverName ?? "",
                                               deviceId: UUID().uuidString,
                                               appId: "PodChat",
                                               peerId: nil,
                                               messageTtl: 10000,
                                               connectionRetryInterval: 5,
                                               reconnectCount: 5,
                                               reconnectOnClose: true,
                                               isDebuggingLogEnabled: true))
struct TestAsyncRefactor: View , NewAsyncDelegate {

    
    @State
    var connectionStatus:String = ""
    
    @State
    var message:String = ""
    
    
    var body: some View {
        VStack{
            HStack(spacing:10){
                Button("click to get profile"){
                    getProfile()
                }
                
                Button("reconnect"){
                    async.reconnect()
                }
            }
            Text(connectionStatus)
            ScrollView{
                Text(message)
            }
        }
        .onAppear {            
            async.delegate = self
        }
    }
    
    func asyncMessage(asyncMessage: NewAsyncMessage) {
        message += "\n\(asyncMessage.content ?? "")\n"
    }
    
    func asyncStateChanged(asyncState: AsyncSocketState, error: Error?) {
        connectionStatus = "\(asyncState)"
        if asyncState == .ASYNC_READY{
            getProfile()
        }
    }
    
    func getProfile(){
        let chatMessage = NewSendChatMessageVO(type:  23,
                                               token:           "cf5ce101e60f4a5c891e94a1adbb31a6" ?? "",
                                            content:            nil,
                                            typeCode:           "default",
                                               uniqueId:           UUID().uuidString)

        guard let chatMessageContent = chatMessage.convertCodableToString() else{return}
        let asyncMessage = NewSendAsyncMessageVO(content:     chatMessageContent,
                                              ttl: 10000,
                                              peerName:     Config.getConfig(.Sandbox)?.serverName ?? "",
                                              priority:     1,
                                              pushMsgType: 3
        )
        let data = try! JSONEncoder().encode(asyncMessage)
        async.sendData(type: .MESSAGE, data: data)
    }

    
    func asyncStateChanged(asyncState: AsyncSocketState, error: AsyncError?) {
        
    }
    
    func asyncError(error: AsyncError) {
        
    }
    
    func asyncMessageSent(message: Data) {
        
    }
    
}

struct TestAsyncRefactor_Previews: PreviewProvider {
    static var previews: some View {
        TestAsyncRefactor(connectionStatus: "Hello",message: "")
    }
}
