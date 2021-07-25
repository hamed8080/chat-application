//
//  AppState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import SwiftUI
import FanapPodChatSDK

class CallState:ObservableObject {
    
    static let shared = CallState()
    
    @Published
    var showCallView = false
    
    @Published
    var connectionStatusString = ""
    
    @Published
    var startCall:StartCall? = nil
    
    var startCallTimer:Timer? = nil
    
    var startCallDate:Date? = nil
    
    @Published
    var timerCallString:String? = nil
    
    
    @Published
    var isCallStarted:Bool = false
    
    @Published
    var mutedCallParticipants:[CallParticipant] = []
    
    @Published
    var unmutedCallParticipants:[CallParticipant] = []
    
    @Published
    var turnOffVideoCallParticipants:[CallParticipant] = []
    
    @Published
    var turnOnVideoCallParticipants:[CallParticipant] = []
    
    
    func setConnectionStatus(_ status:ConnectionStatus){
        if status == .CONNECTED{
            connectionStatusString = ""
        }else{
            connectionStatusString = String(describing: status) + " ..."
        }
    }
	
	var receiveCall:CreateCall? = nil
    
    var isReceiveCall:Bool{
        return receiveCall != nil
    }
	
	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(onReceiveCall(_:)), name: RECEIVE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onRejectCall(_:)), name: REJECTED_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallStarted(_:)), name: STARTED_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallEnd(_:)), name: END_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onMuteParticipants(_:)), name: MUTE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onUNMuteParticipants(_:)), name: UNMUTE_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTurnVideoOnParticipants(_:)), name: TURN_ON_VIDEO_CALL_NAME_OBJECT, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTurnVideoOffParticipants(_:)), name: TURN_OFF_VIDEO_CALL_NAME_OBJECT, object: nil)
	}
    
    var selectedContacts :[Contact] = []
    var isP2PCalling     :Bool      = false
    var callThreadId     :Int?      = nil
    var groupName        :String?   = nil
    
    var titleOfCalling:String{
        if isP2PCalling{
            return selectedContacts.first?.linkedUser?.username ?? "\(selectedContacts.first?.firstName ?? "") \(selectedContacts.first?.lastName ?? "")"
        }else{
            return groupName ?? "Group"
        }
    }
	
	@objc func onReceiveCall(_ notification: NSNotification){
		if let createCall = notification.object as? CreateCall{
			receiveCall = createCall
			showCallView.toggle()
		}
	}
    
    @objc func onRejectCall(_ notification: NSNotification){
        //don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if let _ = notification.object as? Call, showCallView == true{
            showCallView.toggle()
        }
    }
    
    @objc func onCallStarted(_ notification: NSNotification){
        receiveCall = nil //nil to update ui and show call active views
        if let startCall = notification.object as? StartCall{
            self.startCall = startCall
            startCallDate = Date()
            startTimer()
            isCallStarted.toggle()
        }
    }

    func startTimer() {
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                self.timerCallString = self.startCallDate?.getDurationTimerString()
            }
        }
    }
    
    @objc func onCallEnd(_ notification: NSNotification){
        if let callId = notification.object as? Int , startCall?.callId == callId{
            startCall = nil
            resetCall()
            showCallView = false//dissmiss CallControlView and don't use toggle() beacause in callview toggle called when someone tap on end to close view immediately
        }
    }
    
    @objc func onMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            mutedCallParticipants = callParticipants
        }
    }
    
    @objc func onUNMuteParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            unmutedCallParticipants = callParticipants
        }
    }
    
    @objc func onTurnVideoOnParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            turnOnVideoCallParticipants = callParticipants
        }
    }
    
    @objc func onTurnVideoOffParticipants(_ notification: NSNotification){
        if let callParticipants = notification.object as? [CallParticipant]{
            turnOffVideoCallParticipants = callParticipants
        }
    }
    
    func resetCall(){
        startCallTimer          = nil
        timerCallString         = ""
        startCallDate           = nil
        isCallStarted           = false
        mutedCallParticipants   = []
        unmutedCallParticipants = []
    }
}
