//
//  CallControlsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine
import SwiftUI

class CallControlsViewModel: ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    var showToast = false
    
    @Published
    var showCallParticipants:Bool = false
    
    @Published
    var showDetailPanel:Bool = false
    
    @Published
    var activeLargeCall:UserRCT? = nil
    
    @Published
    var location: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height  - 164)

    let appState = AppState.shared

    @Published
    var socketStatus: ConnectionStatus = .connecting
    
    let callState = CallState.shared
    
    private (set) var callId :Int? = nil
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    private (set) var startCallCancelable:AnyCancellable? = nil
    
    
    init() {
        connectionStatusCancelable = appState.$connectionStatus.sink { [weak self] status in
            if let self = self {
                self.socketStatus = status
            }
        }
        startCallCancelable = NotificationCenter.default.publisher(for: CALL_EVENT_NAME)
            .compactMap{$0.object as? CallEventModel}
            .sink { event in
                //NOTICE: sink in init for firsttime is nil
                if case .callStarted(let event) = event.type, let callId = event.callId{
                    self.callId = callId
                }
            }
    }
    
    func startRequestCallIfNeeded(){
        //check if is not incoming call
        if !callState.model.isReceiveCall && !callState.model.isJoinCall{
            if let thread = callState.model.thread{
                satrtCallWithThreadId(thread)
            }
            else if callState.model.isP2PCalling{
                startP2PCall(callState.model.selectedContacts)
            }else{
                startGroupCall(callState.model.selectedContacts)
            }
        }
        let isVideoCall = callState.model.isVideoCall
        let handle = callState.model.receiveCall?.creator.name ?? ""
        AppDelegate.shared?.callMananger.startCall(handle, video: isVideoCall, uuid: callState.model.uuid)
    }
    
    private func startP2PCall(_ selectedContacts:[Contact]){
        let invitees = selectedContacts.map{Invitee(id: "\($0.id ?? 0)", idType: .contactId)}
        let sendClient = SendClient(mute: false, video:  callState.model.isVideoCall)
        Chat.sharedInstance.requestCall(.init(client:sendClient,invitees: invitees, type: callState.model.isVideoCall ? .videoCall : .voiceCall),initCreateCall(createCall:uniqueId:error:))
    }
    
    private func startGroupCall(_ selectedContacts:[Contact]){
        let invitees = selectedContacts.map{Invitee(id: "\($0.id ?? 0)", idType: .contactId)}
        let callType:CallType = callState.model.isVideoCall ? .videoCall : .voiceCall
        let client = SendClient(mute: true, video: callType == .videoCall)
        let callDetail: CreateCallThreadRequest? = .init(title: callState.model.groupName)
        Chat.sharedInstance.requestGroupCall(.init(client:client,invitees: invitees, type: callType, createCallThreadRequest: callDetail),initCreateCall(createCall:uniqueId:error:))
    }
    
    private func satrtCallWithThreadId(_ thread:Conversation){
        let callType:CallType = callState.model.isVideoCall ? .videoCall : .voiceCall
        let client = SendClient(mute: true, video: callType == .videoCall)
        if let threadId = thread.id, thread.group == false {
            Chat.sharedInstance.requestCall(.init(client:client,threadId: threadId, type: callType),initCreateCall(createCall:uniqueId:error:))
        } else if let threadId = thread.id {
            Chat.sharedInstance.requestGroupCall(.init(client:client,threadId: threadId, type: callType),initCreateCall(createCall:uniqueId:error:))
        }
    }
    
    //Create call don't mean the call realy started. CallStarted Event is real one when a call realy accepted by at least one participant.
    private func initCreateCall(createCall:CreateCall? , uniqueId:String? , error:ChatError?) {
        if let createCall = createCall{
            self.callId = createCall.callId
        }
    }
    
    func endCall(){
        endCallKitCall()
        if callState.model.isCallStarted == false {
			cancelCall()
		}else {
			// TODO: realease microphone and camera at the moument and dont need to wait and get response from server
			if let callId = callId{
				Chat.sharedInstance.endCall(.init(subjectId: callId)) { callId, uniqueId, error in
					
				}
			}
		}
        callState.close()
    }
    
    func answerCall(video:Bool, audio:Bool){
        callState.model.setAnswerWithVideo(answerWithVideo: video, micEnable: audio)
        AppDelegate.shared.callMananger.callAnsweredFromCusomUI()
    }
	
	///You can use this method to reject or cancel a call not startrd yet.
	func cancelCall(){
		let callSessionCreated = callState.model.callSessionCreated ?? callState.model.receiveCall
		guard let callId = callSessionCreated?.callId,
			  let creatorId = callSessionCreated?.creatorId,
			  let type = callSessionCreated?.type,
			  let isGroup = callSessionCreated?.group else{return}
		let call = Call(id:callId , creatorId: creatorId, type: type, isGroup: isGroup)
		Chat.sharedInstance.cancelCall(.init(call: call))
        endCallKitCall()
	}
    
    func endCallKitCall(){
        AppDelegate.shared?.callMananger.endCall(callState.model.uuid)
    }
    
    func toggleMic(){                
        callState.toggleMute()
    }
    
    func toggleVideo(){
        callState.toggleCamera()
    }
    
    func toggleSpeaker(){
        callState.toggleSpeaker()
    }
    
    func switchCamera(){
        callState.switchCamera(callState.model.isFrontCamera)
    }
    
    func startRecording(){
        guard let callId = callId else{return}
        Chat.sharedInstance.startRecording(.init(subjectId: callId)) { [weak self] participant, uniqueId, error in
            if let _ = participant, let self = self{
                self.callState.model.setIsRecording(isRecording: true)
                self.callState.model.setStartRecordingDate()
                self.callState.startRecordingTimer()
            }
        }
    }
    
    func stopRecording(){
        guard let callId = callId else{return}
        Chat.sharedInstance.stopRecording(.init(subjectId: callId)) { [weak self] participant, uniqueId, error in
            if let _ = participant, let self = self{
                self.callState.model.setIsRecording(isRecording: false)
                self.callState.model.setStopRecordingDate()
            }
        }
    }
}
