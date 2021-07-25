//
//  CallControlsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine

class CallControlsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    let appState = AppState.shared
    let callState = CallState.shared
    
    @Published
    private (set) var model = CallControlsModel()
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    private (set) var startCallCancelable:AnyCancellable? = nil
    
    
    init() {
        connectionStatusCancelable = appState.$connectionStatus.sink { status in
            if status == .CONNECTED{
              
            }
        }
        
        startCallCancelable = callState.$startCall.sink { startCall in
            if let callId = startCall?.callId{
                self.model.setCallId(callId)
            }
        }
    }
    
    func refresh() {
        clear()
    }
    
    func clear(){
        model.clear()
    }
    
    func startRequestCallIfNeeded(){        
        callState.resetCall()
        //check if is not incoming call
        if !callState.isReceiveCall{
            if let threadId = callState.callThreadId{
                satrtCallWithThreadId(threadId)
            }
            else if callState.isP2PCalling{
                startP2PCall(callState.selectedContacts)
            }else{
                startGroupCall(callState.selectedContacts)
            }
        }
    }
    
    private func startP2PCall(_ selectedContacts:[Contact]){
        let invitees = selectedContacts.map{Invitee(id: "\($0.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)}
        Chat.sharedInstance.requestCall(.init(client:SendClient(),invitees: invitees, type: .VOICE_CALL),initCreateCall(createCall:uniqueId:error:))
    }
    
    private func startGroupCall(_ selectedContacts:[Contact]){
        let invitees = selectedContacts.map{Invitee(id: "\($0.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)}
        Chat.sharedInstance.requestGroupCall(.init(client:SendClient(),invitees: invitees, type: .VOICE_CALL),initCreateCall(createCall:uniqueId:error:))
    }
    
    private func satrtCallWithThreadId(_ threadId:Int){
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
    
    func answerCall(){
        if let receiveCall = callState.receiveCall {
            Chat.sharedInstance.acceptCall(.init(callId:receiveCall.callId, client: .init(mute: true, video: false)))
        }        
    }
    
    func rejectCall(){
        let c = callState.receiveCall
        guard let callId = c?.callId,let creatorId = c?.creatorId , let type = c?.type , let isGroup = c?.group else{return}
        let call = Call(id:callId , creatorId: creatorId, type: type, isGroup: isGroup)
        Chat.sharedInstance.rejectCall(.init(call: call))
    }
    
    func toggleMute(){
        guard let currentUserId = Chat.sharedInstance.getCurrentUser()?.id , let callId = model.callId else{return}
        if model.isMute{
            Chat.sharedInstance.unmuteCall(.init(callId: callId, userIds: [currentUserId])) { participants, uniqueId, error in
                
            }
        }else{
            Chat.sharedInstance.muteCall(.init(callId: callId, userIds: [currentUserId])) { participants, uniqueId, error in
                
            }
        }
        model.toggleMute()
    }
    
    func toggleVideo(){
        guard let callId = model.callId else{return}
        model.toggleVideo()
        if model.isVideoOn{
            Chat.sharedInstance.turnOnVideoCall(.init(callId: callId)) { participants, uniqueId, error in
            }
        }else{
            Chat.sharedInstance.turnOffVideoCall(.init(callId: callId)) { participants, uniqueId, error in
            }
        }
        
    }
    
    func toggleSpeaker(){
        
    }
    
    func setupPreview(){
        model.setupPreview()
    }
}
