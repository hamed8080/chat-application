//
//  CallControlsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

class CallControlsViewModel:ObservableObject{
    
    var isLoading = false
    
    @Published
    private (set) var model = CallControlsModel()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onConnectionStatusChanged(_:)), name: CONNECTION_STATUS_NAME_OBJECT, object: nil)
    }
    
    @objc private func onConnectionStatusChanged(_ notification:NSNotification){
        if let connectionStatus = notification.object as? ConnectionStatus{
            model.setConnectionStatus(connectionStatus)
        }
    }
    
    func refresh() {
        clear()
    }
    
    func clear(){
        model.clear()
    }
    
    func startGroupCall(_ selectedContacts:[Contact]){
        let invitees = selectedContacts.map{Invitee(id: "\($0.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)}
        Chat.sharedInstance.requestGroupCall(.init(client:SendClient(),invitees: invitees, type: .VOICE_CALL),initCreateCall(createCall:uniqueId:error:))
    }
    
    func startP2PCall(_ selectedContacts:[Contact]){
        let invitees = selectedContacts.map{Invitee(id: "\($0.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)}
        Chat.sharedInstance.requestCall(.init(client:SendClient(),invitees: invitees, type: .VOICE_CALL),initCreateCall(createCall:uniqueId:error:))
    }
    
    func satrtCallWithThreadId(_ threadId:Int){
        Chat.sharedInstance.requestCall(.init(client:SendClient(),threadId: threadId, type: .VOICE_CALL),initCreateCall(createCall:uniqueId:error:))
    }
    
    
    //Create call don't mean the call realy started. CallStarted Event is real one when a call realy accepted by at least one participant.
    private func initCreateCall(createCall:CreateCall? , uniqueId:String? , error:ChatError?) {
        if let createCall = createCall{
            self.model.setCallId(createCall.callId)
        }
    }
    
    func endCall(){
        // TODO: realease microphone and camera at the moument and dont need to wait and get response from server
        if let callId = model.callId{
            Chat.sharedInstance.endCall(.init(callId: callId)) { callId, uniqueId, error in
                
            }
        }
        model.endCall()
    }
    
    func toggleMute(){
        guard let currentUserId = Chat.sharedInstance.getCurrentUser()?.id , let callId = model.callId else{return}
        if model.isMute{
            Chat.sharedInstance.unmuteCall(.init(callId: callId, userIds: [currentUserId])) { participants, uniqueId, error in
                if participants?.count ??  0 > 0  && error == nil{
                    self.model.setMute(false)
                }
            }
        }else{
            Chat.sharedInstance.muteCall(.init(callId: callId, userIds: [currentUserId])) { participants, uniqueId, error in
                if participants?.count ??  0 > 0  && error == nil{
                    self.model.setMute(true)
                }
            }
        }
    }
    
    func toggleVideo(){
        guard let callId = model.callId else{return}
        if model.isVideoOn{
            Chat.sharedInstance.turnOnVideoCall(.init(callId: callId)) { participants, uniqueId, error in
                if participants?.count ??  0 > 0  && error == nil{
                    self.model.setVideo(false)
                }
            }
        }else{
            Chat.sharedInstance.turnOffVideoCall(.init(callId: callId)) { participants, uniqueId, error in
                if participants?.count ??  0 > 0  && error == nil{
                    self.model.setVideo(true)
                }
            }
        }
    }
    
    func setupPreview(){
        model.setupPreview()
    }
}
