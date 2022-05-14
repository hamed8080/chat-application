//
//  CallState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI
import FanapPodChatSDK
import WebRTC


struct CallStateModel {
    private (set) var uuid                         :UUID              = UUID()
    private (set) var startCall                    :StartCall?        = nil
    private (set) var showCallView                 :Bool              = false
    private (set) var connectionStatusString       :String            = ""
    private (set) var startCallDate                :Date?             = nil
    private (set) var startRecodrdingDate          :Date?             = nil
    private (set) var timerCallString              :String?           = nil
    private (set) var recordingTimerString         :String?           = nil
    private (set) var isCallStarted                :Bool              = false
    private (set) var usersRTC                     :[UserRCT]         = []
    private (set) var receiveCall                  :CreateCall?       = nil
	private (set) var callSessionCreated           :CreateCall?       = nil
    private (set) var selectedContacts             :[Contact]         = []
    private (set) var thread                       :Conversation?     = nil
    private (set) var isP2PCalling                 :Bool              = false
    private (set) var isVideoCall                  :Bool              = false
    private (set) var groupName                    :String?           = nil
    private (set) var answerWithVideo              :Bool              = false
    private (set) var answerWithMicEnable          :Bool              = false
    private (set) var isRecording                  :Bool              = false
    private (set) var callRecorder                 :Participant?      = nil
    private (set) var isJoinCall                   :Bool              = false
    private (set) var isSpeakerOn                  :Bool              = false
    private (set) var isFrontCamera                :Bool              = true
    
    mutating func setReceiveCall(_ receiveCall:CreateCall){
        self.receiveCall = receiveCall
        self.isVideoCall = receiveCall.type == .VIDEO_CALL
    }
    
    mutating func setShowCallView(_ showCallView:Bool){
        self.showCallView = showCallView
    }
    
    mutating func setIsJoinCall(_ joinCall:Bool){
        self.isJoinCall = joinCall
    }
    
    mutating func setConnectionState(_ stateString:String){
        self.connectionStatusString = stateString
    }
    
    mutating func addUserRTC(_ userRTC :UserRCT){
        if usersRTC.first(where: {$0.topic == userRTC.topic}) != nil{
            replaceUserRTC(userRTC)
        }else{
            self.usersRTC.append(userRTC)
        }
    }
    
    mutating func removeUserRTC(_ userRTC :UserRCT){
        usersRTC.removeAll(where: {$0.topic == userRTC.topic})
    }
    
    mutating func replaceUserRTC(_ userRTC:UserRCT){
        if let index = usersRTC.firstIndex(where: {$0.topic == userRTC.topic}){
            usersRTC[index] = userRTC
        }
    }
    
    mutating func setStartDate(){
        self.startCallDate = Date()
    }
    
    mutating func setStartRecordingDate(){
        self.startRecodrdingDate = Date()
    }
    
    mutating func setStopRecordingDate(){
        self.startRecodrdingDate = nil
    }
    
    mutating func setStartedCall(_ startCall:StartCall){
        self.startCall = startCall
        isCallStarted = true
        setStartDate()
    }
    
	mutating func setCallSessionCreated(_ createCall:CreateCall){
		self.callSessionCreated = createCall
	}
	
    mutating func setTimerString(_ timerString:String?){
        self.timerCallString = timerString
    }
    
    mutating func setRecordingTimerString(_ recordingTimerString:String?){
        self.recordingTimerString = recordingTimerString
    }
    
    mutating func setIsP2PCalling(_ isP2PCalling:Bool){
        self.isP2PCalling = isP2PCalling
    }
    
    mutating func setSelectedContacts(_ selectedContacts:[Contact]){
        self.selectedContacts.append(contentsOf: selectedContacts)
    }
    
    mutating func setSelectedThread(_ thread:Conversation?){
        self.thread = thread
    }
    
    mutating func setIsVideoCallRequest(_ isVideoCall:Bool){
        self.isVideoCall = isVideoCall
    }
    
    mutating func setAnswerWithVideo(answerWithVideo:Bool , micEnable:Bool){
        self.answerWithVideo = answerWithVideo
        self.answerWithMicEnable = micEnable
    }
   
    var isReceiveCall:Bool{
        return receiveCall != nil
    }
    
    var titleOfCalling:String{
        if let thread = thread{
            return thread.title ?? ""
        }else if isP2PCalling{
            return selectedContacts.first?.linkedUser?.username ?? "\(selectedContacts.first?.firstName ?? "") \(selectedContacts.first?.lastName ?? "")"
        }else{
            return groupName ?? "Group"
        }
    }
    
    mutating func setIsRecording(isRecording:Bool){
        self.isRecording = isRecording
    }
    
    mutating func setStartRecording(participant:Participant){
        setIsRecording(isRecording: true)
        self.callRecorder = participant
    }
    
    mutating func setStopRecording(participant:Participant){
        setIsRecording(isRecording: false)
        self.callRecorder = nil
    }
    
    mutating func muteParticipants(_ callParticipants:[CallParticipant]){
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: { $0.isAudioTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id}){
                usersRTC[index].setMute(mute: true)
            }
        }
    }
    
    mutating func unmuteParticipants(_ callParticipants:[CallParticipant]){
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: { $0.isAudioTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id}){
                usersRTC[index].setMute(mute: false)
            }
        }
    }
    
    mutating func turnOnVideoParticipants(_ callParticipants:[CallParticipant]){
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: {$0.isVideoTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id}){
                usersRTC[index].setVideo(on: true)
            }
        }
    }
    
    mutating func turnOffVideoParticipants(_ callParticipants:[CallParticipant]){
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: {$0.isVideoTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id}){
                usersRTC[index].setVideo(on: false)
            }
        }
    }
    
    mutating func updateCallParticipants(_ participants:[CallParticipant]?){
        participants?.forEach({ callParticipant in
            usersRTC.filter{ $0.rawTopicName == callParticipant.sendTopic}.forEach{ user in
                let index = usersRTC.firstIndex(of: user)!
                usersRTC[index].setCallParticipant(callParticipant)
            }
        })
    }
    
    mutating func setUserIsSpeaking(_ participant:CallParticipant){
        if let user = usersRTC.first(where: {$0.rawTopicName == participant.sendTopic && $0.isVideoTopic}){
            let index = usersRTC.firstIndex(of: user)!
            usersRTC[index].isSpeaking = true
        }
    }
    
    mutating func setUserSoppedSpeaking(_ participant:CallParticipant){
        if let user = usersRTC.first(where: {$0.rawTopicName == participant.sendTopic && $0.isVideoTopic}){
            let index = usersRTC.firstIndex(of: user)!
            usersRTC[index].isSpeaking = false
        }
    }
    
    mutating func toggleSpeaker(){
        self.isSpeakerOn.toggle()
    }

}

class CallState:ObservableObject,WebRTCClientDelegate {
   
    public static  let shared        :CallState         = CallState()
    
    @Published
    var model          :CallStateModel    = CallStateModel()
    
    private (set) var startCallTimer :Timer?            = nil
    private (set) var recordingTimer :Timer?            = nil
    
    func setConnectionStatus(_ status:ConnectionStatus){
        model.setConnectionState( status == .CONNECTED ? "" : String(describing: status) + " ...")
    }

	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(onCallSessionCreated(_:)), name: CALL_SESSION_CREATED_NAME_OBJECT, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(onReceiveCall(_:)), name: RECEIVE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallCanceled(_:)), name: CANCELED_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallStarted(_:)), name: STARTED_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallEnd(_:)), name: END_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMuteParticipants(_:)), name: MUTE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onUNMuteParticipants(_:)), name: UNMUTE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTurnVideoOnParticipants(_:)), name: TURN_ON_VIDEO_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTurnVideoOffParticipants(_:)), name: TURN_OFF_VIDEO_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallStartRecording(_:)), name: START_CALL_RECORDING_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallStopRecording(_:)), name: STOP_CALL_RECORDING_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallParticipantJoined(_:)), name: CALL_PARTICIPANT_JOINED_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallParticipantLeft(_:)), name: CALL_PARTICIPANT_LEFT_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallParticipantSpeaking(_:)), name: CALL_PARTICIPANT_IS_SPEAKING_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallParticipantStoppedSpeaking(_:)), name: CALL_PARTICIPANT_STOPPED_SPEAKING_NAME_OBJECT, object: nil)
	}
	
	@objc func onCallSessionCreated(_ notification: NSNotification){
		if let createCall = notification.object as? CreateCall{
			model.setCallSessionCreated(createCall)
		}
	}
	
	@objc func onReceiveCall(_ notification: NSNotification){
		if let createCall = notification.object as? CreateCall{
            model.setShowCallView(true)
            model.setReceiveCall(createCall)
            AppDelegate.shared.providerDelegate?.reportIncomingCall(uuid: model.uuid, handle: model.titleOfCalling, hasVideo: model.isVideoCall, completion: nil)
		}
	}
	
	//maybe reject or canceled after a time out
    @objc func onCallCanceled(_ notification: NSNotification){
        //don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if let _ = notification.object as? Call, model.showCallView{
            model.setShowCallView(false)
            endCallKitCall()
			resetCall()
        }
    }
    
    @objc func onCallStarted(_ notification: NSNotification){
        
        if let startCall = notification.object as? StartCall{
            model.setStartedCall(startCall)
            startTimer()
            ///simulator File name
            let smFileName = TARGET_OS_SIMULATOR != 0 ? "webrtc_user_a.mp4" : nil
            let config = WebRTCConfig(startCall: startCall, isSendVideoEnabled: model.answerWithVideo || model.isVideoCall,fileName: smFileName)
            WebRTCClientNew.instance = WebRTCClientNew(config: config , delegate: self)
            addCallParicipant(.init(sendTopic: config.topicSend ?? "",
                                              mute: startCall.clientDTO.mute,
                                              video: startCall.clientDTO.video,
                                              participant: .init(name:"ME")
                                             ),
                              direction:.SEND)
            startCall.otherClientDtoList?.filter({$0.clientId != startCall.clientDTO.clientId}).forEach({ clientDTO in
                let callParticipant = CallParticipant(sendTopic: clientDTO.topicSend,mute: clientDTO.mute, video: clientDTO.video)
                addCallParicipant(callParticipant)
            })
            WebRTCClientNew.instance?.createSession()
            fetchCallParticipants(startCall)
        }
    }

    func fetchCallParticipants(_ startCall:StartCall) {
        guard let callId = startCall.callId else{return}
        Chat.sharedInstance.activeCallParticipants(.init(callId: callId)) { callParticipants, uniqueId, error in
            
            //update only call participants who not current user
            if let callParticipants = callParticipants?.filter({$0.userId != startCall.clientDTO.userId}){
                self.model.updateCallParticipants(callParticipants)
                WebRTCClientNew.instance?.updateCallParticipant(callParticipants: callParticipants)
            }
        }
    }
    
    @objc func onCallEnd(_ notification: NSNotification){
        endCallKitCall()        
        model.setShowCallView(false)
        ResultViewController.printCallLogsFile()
        WebRTCClientNew.instance?.clearResourceAndCloseConnection()
        resetCall()
    }
    
    @objc func onMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.muteParticipants(callParticipants)
        }
    }
    
    @objc func onUNMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.unmuteParticipants(callParticipants)
        }
    }
    
    @objc func onTurnVideoOnParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.turnOnVideoParticipants(callParticipants)
        }
    }
    
    @objc func onTurnVideoOffParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.turnOffVideoParticipants(callParticipants)
        }
    }
    
    @objc func onCallStartRecording(_ notification: NSNotification){
        if let recorder = notification.object as? Participant{
            model.setStartRecording(participant: recorder)
        }
    }
    
    @objc func onCallStopRecording(_ notification: NSNotification){
        if let recorder = notification.object as? Participant{
            model.setStopRecording(participant: recorder)
        }
    }
    
    /// Setup UI and WEBRCT for new participant joined to the call
    @objc func onCallParticipantJoined(_ notification: NSNotification){
        (notification.object as? [CallParticipant])?.forEach { callParticipant in
            addCallParicipant(callParticipant)
        }
    }
    
    /// Setup UI and WEBRCT for new participant joined to the call
    @objc func onCallParticipantLeft(_ notification: NSNotification){
        (notification.object as? [CallParticipant])?.forEach { callParticipant in
            removeCallParticipant(callParticipant)
        }
    }
    
    @objc func onCallParticipantSpeaking(_ notification: NSNotification){
        if let callParticipant = notification.object as? CallParticipant{
            model.setUserIsSpeaking(callParticipant)
        }
    }
    
    @objc func onCallParticipantStoppedSpeaking(_ notification: NSNotification){
        if let callParticipant = notification.object as? CallParticipant{
            model.setUserSoppedSpeaking(callParticipant)
        }
    }
    
    func resetCall(){
        startCallTimer?.invalidate()
        startCallTimer           = nil
        model                    = CallStateModel()
        WebRTCClientNew.instance = nil
    }
    
    func toggleSpeaker(){
        WebRTCClientNew.instance?.toggleSpeaker()
        model.toggleSpeaker()
    }
    
    func toggleMute(){
        guard let currentUserId = Chat.sharedInstance.userInfo?.id , let callId = model.startCall?.callId else{return}
        let oldIsMuteState = model.usersRTC.first(where:{$0.direction == .SEND && $0.isAudioTopic})?.isMute ?? true
        let newIsMuteState = !oldIsMuteState
        if oldIsMuteState{
            Chat.sharedInstance.unmuteCall(.init(callId: callId, userIds: [currentUserId])) { participants, uniqueId, error in
                
            }
        }else{
            Chat.sharedInstance.muteCall(.init(callId: callId, userIds: [currentUserId])) { participants, uniqueId, error in
                
            }
        }
        
        WebRTCClientNew.instance?.setMute(newIsMuteState)
        if let index = model.usersRTC.firstIndex(where: {$0.isAudioTopic && $0.direction == .SEND}), let callParticipant = model.usersRTC[index].callParticipant{
            if newIsMuteState{
                model.muteParticipants([callParticipant])
            }else{
                model.unmuteParticipants([callParticipant])
            }
        }
    }
    
    func toggleCamera(){
        guard let callId = model.startCall?.callId else{return}
        let isVideoOnOldState = model.usersRTC.first(where:{$0.direction == .SEND && $0.isVideoTopic})?.isVideoOn ?? false
        let isVideoOnNewState = !isVideoOnOldState
        if isVideoOnOldState{
            Chat.sharedInstance.turnOffVideoCall(.init(callId: callId)) { participants, uniqueId, error in
            }
        }else{
            Chat.sharedInstance.turnOnVideoCall(.init(callId: callId)) { participants, uniqueId, error in
            }
        }
        
        WebRTCClientNew.instance?.setCameraIsOn(isVideoOnNewState)
        if let index = model.usersRTC.firstIndex(where: {$0.isVideoTopic && $0.direction == .SEND}), let callParticipant = model.usersRTC[index].callParticipant{
            if isVideoOnNewState{
                model.turnOnVideoParticipants([callParticipant])
            }else{
                model.turnOffVideoParticipants([callParticipant])
            }
        }
    }
    
    func switchCamera(_ isFront:Bool){
//        guard let localVideoRenderer = localVideoRenderer else{return}
//        GroupWebRTCClientNew.instance?.switchCameraPosition(renderer: localVideoRenderer)
    }
    
    func close(){
        WebRTCClientNew.instance?.clearResourceAndCloseConnection()
        ResultViewController.printCallLogsFile()
        resetCall()
    }
    
    func startTimer() {
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[weak self] timer in
            DispatchQueue.main.async {
                self?.model.setTimerString(self?.model.startCallDate?.getDurationTimerString())
            }
        }
    }
    
    func endCallKitCall(){
        AppDelegate.shared?.callMananger.endCall(model.uuid)
    }
    
    func startRecordingTimer(){
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                self?.model.setRecordingTimerString(self?.model.startRecodrdingDate?.getDurationTimerString())
            }
        }
    }
    
    func addCallParicipant(_ callParticipant:CallParticipant, direction:RTCDirection = .RECEIVE){
        WebRTCClientNew.instance?.addCallParticipant(callParticipant, direction: direction)
        let addedTopics = WebRTCClientNew.instance?.usersRTC.filter{$0.topic == topics(callParticipant).topicVideo || $0.topic == topics(callParticipant).topicAudio}
        addedTopics?.forEach({ userRTC in
            model.addUserRTC(userRTC)
        })
    }
    
    func removeCallParticipant(_ callParticipant:CallParticipant){
        WebRTCClientNew.instance?.removeCallParticipant(callParticipant)
        model.usersRTC.filter{$0.topic == topics(callParticipant).topicVideo || $0.topic == topics(callParticipant).topicAudio }.forEach { userRTC in
            model.removeUserRTC(userRTC)
        }
    }

    private func topics(_ callParticipant:CallParticipant)->(topicVideo:String,topicAudio:String){
        return ("Vi-\(callParticipant.sendTopic)","Vo-\(callParticipant.sendTopic)")
    }
}

//Implement WebRTCClientDelegate
extension CallState{
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {
        
    }
    
    func didReceiveData(data: Data) {
        
    }
    
    func didReceiveMessage(message: String) {
        
    }
    
    func didConnectWebRTC() {
        
    }
    
    func didDisconnectWebRTC() {
        
    }
}
