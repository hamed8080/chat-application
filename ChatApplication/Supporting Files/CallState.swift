//
//  AppState.swift
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
    private (set) var mutedCallParticipants        :[CallParticipant] = []
    private (set) var unmutedCallParticipants      :[CallParticipant] = []
    private (set) var turnOffVideoCallParticipants :[CallParticipant] = []
    private (set) var turnOnVideoCallParticipants  :[CallParticipant] = []
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
    
    
    mutating func setReceiveCall(_ receiveCall:CreateCall){
        self.receiveCall = receiveCall
        self.isVideoCall = receiveCall.type == .VIDEO_CALL
    }
    
    mutating func setShowCallView(_ showCallView:Bool){
        self.showCallView = showCallView
    }
    
    mutating func setConnectionState(_ stateString:String){
        self.connectionStatusString = stateString
    }
    
    mutating func addTurnOnCallParticipant(_ participants :[CallParticipant]){
        self.turnOnVideoCallParticipants.append(contentsOf: participants)
    }
    
    mutating func addTurnOffCallParticipant(_ participants :[CallParticipant]){
        self.turnOffVideoCallParticipants.append(contentsOf: participants)
    }
    
    mutating func addMuteCallParticipant(_ participants :[CallParticipant]){
        self.mutedCallParticipants.append(contentsOf: participants)
    }
    
    mutating func addUnMuteCallParticipant(_ participants :[CallParticipant]){
        self.unmutedCallParticipants.append(contentsOf: participants)
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
}

class CallState:ObservableObject,WebRTCClientDelegate {
   
    public static  let shared        :CallState         = CallState()
    
    @Published
    var model          :CallStateModel    = CallStateModel()
    
    private (set) var startCallTimer :Timer?            = nil
    private (set) var recordingTimer :Timer?            = nil
    
    
    var localVideoRenderer  :RTCVideoRenderer? = nil
    var remoteVideoRenderer :RTCVideoRenderer? = nil
    
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
            
            //Vo - Voice and Vi- Video its hardcoded in all sdks such as:Android-Js,...
            let config =  WebRTCConfig(peerName           : startCall.chatDataDto.kurentoAddress,
                                      iceServers          : ["turn:\(startCall.chatDataDto.turnAddress)?transport=udp",
															 "turn:\(startCall.chatDataDto.turnAddress)?transport=tcp"],//"stun:46.32.6.188:3478",
                                      turnAddress         : startCall.chatDataDto.turnAddress,
                                       topicVideoSend      : model.answerWithVideo || model.isVideoCall ? "Vi-\(startCall.clientDTO.topicSend)" : nil,
                                      topicVideoReceive   : "Vi-\(startCall.clientDTO.topicReceive)",
                                      topicAudioSend      : "Vo-\(startCall.clientDTO.topicSend)",
                                      topicAudioReceive   : "Vo-\(startCall.clientDTO.topicReceive)",
                                      brokerAddressWeb    : startCall.chatDataDto.brokerAddressWeb,
                                      dataChannel         : false,
                                      customFrameCapturer : false,
                                      userName            : "mkhorrami",
                                      password            : "mkh_123456",
                                      videoConfig         : nil)
            WebRTCClientNew.instance = WebRTCClientNew(config: config , delegate: self)
            if let renderer = localVideoRenderer {
                WebRTCClientNew.instance?.startCaptureLocalVideo(renderer: renderer,fileName: model.isReceiveCall ? "webrtc_user_b.mp4" : "webrtc_user_a.mp4")
            }

            if let renderer = remoteVideoRenderer {
                WebRTCClientNew.instance?.renderRemoteVideo(renderer)
            }
            WebRTCClientNew.instance?.startSendKeyFrame()
        }
    }

    
    @objc func onCallEnd(_ notification: NSNotification){
        endCallKitCall()
        ResultViewController.printCallLogsFile()
        model.setShowCallView(false)
        WebRTCClientNew.instance?.clearResourceAndCloseConnection()
        resetCall()
    }
    
    @objc func onMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addMuteCallParticipant(callParticipants)
        }
    }
    
    @objc func onUNMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addUnMuteCallParticipant(callParticipants)
        }
    }
    
    @objc func onTurnVideoOnParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addTurnOnCallParticipant(callParticipants)
        }
    }
    
    @objc func onTurnVideoOffParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            model.addTurnOffCallParticipant(callParticipants)
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
    
    func resetCall(){
        localVideoRenderer       = nil
        remoteVideoRenderer      = nil
        startCallTimer?.invalidate()
        startCallTimer           = nil
        model                    = CallStateModel()
        WebRTCClientNew.instance = nil
    }
    
    func setLocalVideoRenderer(_ renderer:RTCVideoRenderer){
        localVideoRenderer  = renderer
    }
    
    func setRemoteVideoRenderer(_ renderer:RTCVideoRenderer){
        remoteVideoRenderer  = renderer
    }
    
    func setSpeaker(_ isOn:Bool){
        WebRTCClientNew.instance?.setSpeaker(on: isOn)
    }
    
    func setMute(_ isMute:Bool){
        WebRTCClientNew.instance?.setMute(isMute)
    }
    
    func setCameraIsOn(_ isCameraOn:Bool){
        WebRTCClientNew.instance?.setCameraIsOn(isCameraOn)
    }
    
    func switchCamera(_ isFront:Bool){
        guard let localVideoRenderer = localVideoRenderer else{return}
        WebRTCClientNew.instance?.switchCameraPosition(renderer: localVideoRenderer)
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
