//
//  CallState.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI
import WebRTC

struct CallStateModel {
    private(set) var uuid: UUID = .init()
    private(set) var startCall: StartCall? = nil
    private(set) var showCallView: Bool = false
    private(set) var connectionStatusString: String = ""
    private(set) var startCallDate: Date? = nil
    private(set) var startRecodrdingDate: Date? = nil
    private(set) var timerCallString: String? = nil
    private(set) var recordingTimerString: String? = nil
    private(set) var isCallStarted: Bool = false
    var usersRTC: [UserRCT] = []
    private(set) var receiveCall: CreateCall? = nil
    private(set) var callSessionCreated: CreateCall? = nil
    private(set) var selectedContacts: [Contact] = []
    private(set) var thread: Conversation? = nil
    private(set) var isP2PCalling: Bool = false
    private(set) var isVideoCall: Bool = false
    private(set) var groupName: String? = nil
    private(set) var answerWithVideo: Bool = false
    private(set) var answerWithMicEnable: Bool = false
    private(set) var isRecording: Bool = false
    private(set) var callRecorder: Participant? = nil
    private(set) var isJoinCall: Bool = false
    private(set) var isSpeakerOn: Bool = false
    private(set) var isFrontCamera: Bool = true

    mutating func setGroupName(name: String) {
        groupName = name
    }

    mutating func setReceiveCall(_ receiveCall: CreateCall) {
        self.receiveCall = receiveCall
        isVideoCall = receiveCall.type == .videoCall
    }

    mutating func setShowCallView(_ showCallView: Bool) {
        self.showCallView = showCallView
    }

    mutating func setIsJoinCall(_ joinCall: Bool) {
        isJoinCall = joinCall
    }

    mutating func setConnectionState(_ stateString: String) {
        connectionStatusString = stateString
    }

    mutating func addUserRTC(_ userRTC: UserRCT) {
        if usersRTC.first(where: { $0.topic == userRTC.topic }) != nil {
            replaceUserRTC(userRTC)
        } else {
            usersRTC.append(userRTC)
        }
    }

    mutating func removeUserRTC(_ userRTC: UserRCT) {
        usersRTC.removeAll(where: { $0.topic == userRTC.topic })
    }

    mutating func replaceUserRTC(_ userRTC: UserRCT) {
        if let index = usersRTC.firstIndex(where: { $0.topic == userRTC.topic }) {
            usersRTC[index] = userRTC
        }
    }

    mutating func setStartDate() {
        startCallDate = Date()
    }

    mutating func setStartRecordingDate() {
        startRecodrdingDate = Date()
    }

    mutating func setStopRecordingDate() {
        startRecodrdingDate = nil
    }

    mutating func setStartedCall(_ startCall: StartCall) {
        self.startCall = startCall
        isCallStarted = true
        setStartDate()
    }

    mutating func setCallSessionCreated(_ createCall: CreateCall) {
        callSessionCreated = createCall
    }

    mutating func setTimerString(_ timerString: String?) {
        timerCallString = timerString
    }

    mutating func setRecordingTimerString(_ recordingTimerString: String?) {
        self.recordingTimerString = recordingTimerString
    }

    mutating func setIsP2PCalling(_ isP2PCalling: Bool) {
        self.isP2PCalling = isP2PCalling
    }

    mutating func setSelectedContacts(_ selectedContacts: [Contact]) {
        self.selectedContacts.append(contentsOf: selectedContacts)
    }

    mutating func setSelectedThread(_ thread: Conversation?) {
        self.thread = thread
    }

    mutating func setIsVideoCallRequest(_ isVideoCall: Bool) {
        self.isVideoCall = isVideoCall
    }

    mutating func setAnswerWithVideo(answerWithVideo: Bool, micEnable: Bool) {
        self.answerWithVideo = answerWithVideo
        answerWithMicEnable = micEnable
    }

    var isReceiveCall: Bool {
        return receiveCall != nil
    }

    var titleOfCalling: String {
        if let thread = thread {
            return thread.title ?? ""
        } else if isP2PCalling {
            return selectedContacts.first?.linkedUser?.username ?? "\(selectedContacts.first?.firstName ?? "") \(selectedContacts.first?.lastName ?? "")"
        } else {
            return groupName ?? "Group"
        }
    }

    mutating func setIsRecording(isRecording: Bool) {
        self.isRecording = isRecording
    }

    mutating func setStartRecording(participant: Participant) {
        setIsRecording(isRecording: true)
        callRecorder = participant
    }

    mutating func setStopRecording(participant: Participant) {
        setIsRecording(isRecording: false)
        callRecorder = nil
    }

    mutating func muteParticipants(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: { $0.isAudioTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id }) {
                usersRTC[index].setMute(mute: true)
            }
        }
    }

    mutating func unmuteParticipants(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: { $0.isAudioTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id }) {
                usersRTC[index].setMute(mute: false)
            }
        }
    }

    mutating func turnOnVideoParticipants(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: { $0.isVideoTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id }) {
                usersRTC[index].setVideo(on: true)
            }
        }
    }

    mutating func turnOffVideoParticipants(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let index = usersRTC.firstIndex(where: { $0.isVideoTopic && $0.callParticipant?.participant?.id == callParticipant.participant?.id }) {
                usersRTC[index].setVideo(on: false)
            }
        }
    }

    mutating func updateCallParticipants(_ participants: [CallParticipant]?) {
        participants?.forEach { callParticipant in
            usersRTC.filter { $0.rawTopicName == callParticipant.sendTopic }.forEach { user in
                let index = usersRTC.firstIndex(of: user)!
                usersRTC[index].setCallParticipant(callParticipant)
            }
        }
    }

    mutating func setUserIsSpeaking(_ participant: CallParticipant) {
        if let user = usersRTC.first(where: { $0.rawTopicName == participant.sendTopic && $0.isVideoTopic }) {
            let index = usersRTC.firstIndex(of: user)!
            usersRTC[index].isSpeaking = true
        }
    }

    mutating func setUserSoppedSpeaking(_ participant: CallParticipant) {
        if let user = usersRTC.first(where: { $0.rawTopicName == participant.sendTopic && $0.isVideoTopic }) {
            let index = usersRTC.firstIndex(of: user)!
            usersRTC[index].isSpeaking = false
        }
    }

    mutating func toggleSpeaker() {
        isSpeakerOn.toggle()
    }
}

class CallState: ObservableObject, WebRTCClientDelegate {
    public static let shared: CallState = .init()

    @Published
    var model: CallStateModel = .init()

    private(set) var startCallTimer: Timer?
    private(set) var recordingTimer: Timer?
    private(set) var cancellableSet: Set<AnyCancellable> = []

    func setConnectionStatus(_ status: ConnectionStatus) {
        model.setConnectionState(status == .connected ? "" : String(describing: status) + " ...")
    }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(callEvent(_:)), name: CALL_EVENT_NAME, object: nil)
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if model.startCall != nil, status == .connected {
            callInquiry()
        }
    }

    @objc func callEvent(_ notification: NSNotification) {
        guard let type = (notification.object as? CallEventTypes) else { return }
        switch type {
        case .callStarted(let startCall):
            onCallStarted(startCall)
        case .callCreate(let createCall):
            onCallCreated(createCall)
        case .callReceived(let receieveCall):
            onReceiveCall(receieveCall)
        case .callDelivered:
            break
        case .callEnded(let callId):
            onCallEnd(callId)
        case .groupCallCanceled(let call):
            onCallEnd(call.callId)
        case .callCanceled(let canceledCall):
            onCallCanceled(canceledCall)
        case .callRejected:
            break
        case .startCallRecording(let participant):
            onCallStartRecording(participant)
        case .stopCallRecording(let participant):
            onCallStopRecording(participant)
        case .callParticipantJoined(let callParticipants):
            onCallParticipantJoined(callParticipants)
        case .callParticipantLeft(let callParticipants):
            onCallParticipantLeft(callParticipants)
        case .callParticipantMute(let callParticipants):
            onMuteParticipants(callParticipants)
        case .callParticipantUnmute(let callParticipants):
            onUNMuteParticipants(callParticipants)
        case .callParticipantsRemoved:
            break
        case .turnVideoOn(let callParticipants):
            onTurnVideoOnParticipants(callParticipants)
        case .turnVideoOff(let callParticipants):
            onTurnVideoOffParticipants(callParticipants)
        case .callClientError:
            break
        case .callParticipantStartSpeaking(let callParticipants):
            onCallParticipantSpeaking(callParticipants)
        case .callParticipantStopSpeaking(let callParticipants):
            onCallParticipantStoppedSpeaking(callParticipants)
        }
    }

    func onCallCreated(_ createCall: CreateCall) {
        model.setCallSessionCreated(createCall)
    }

    func onReceiveCall(_ createCall: CreateCall) {
        model.setShowCallView(true)
        model.setReceiveCall(createCall)
        AppDelegate.shared.providerDelegate?.reportIncomingCall(uuid: model.uuid, handle: model.titleOfCalling, hasVideo: model.isVideoCall, completion: nil)
    }

    // maybe reject or canceled after a time out
    func onCallCanceled(_ canceledCall: Call) {
        // don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if model.showCallView {
            model.setShowCallView(false)
            endCallKitCall()
            resetCall()
        }
    }

    func onCallStarted(_ startCall: StartCall) {
        model.setStartedCall(startCall)
        startTimer()
        /// simulator File name
        let smFileName = TARGET_OS_SIMULATOR != 0 ? "webrtc_user_a.mp4" : nil
        let config = WebRTCConfig(startCall: startCall, isSendVideoEnabled: model.answerWithVideo || model.isVideoCall, fileName: smFileName)
        WebRTCClient.instance = WebRTCClient(config: config, delegate: self)
        addCallParicipant(.init(sendTopic: config.topicSend ?? "",
                                mute: startCall.clientDTO.mute,
                                video: startCall.clientDTO.video,
                                participant: .init(name: "ME")),
                          direction: .send)
        startCall.otherClientDtoList?.filter { $0.clientId != startCall.clientDTO.clientId }.forEach { clientDTO in
            let callParticipant = CallParticipant(sendTopic: clientDTO.topicSend, mute: clientDTO.mute, video: clientDTO.video)
            addCallParicipant(callParticipant)
        }
        WebRTCClient.instance?.createSession()
        fetchCallParticipants(startCall)
    }

    func fetchCallParticipants(_ startCall: StartCall) {
        guard let callId = startCall.callId else { return }
        Chat.sharedInstance.activeCallParticipants(.init(subjectId: callId)) { callParticipants, _, _ in

            // update only call participants who not current user
            if let callParticipants = callParticipants?.filter({ $0.userId != startCall.clientDTO.userId }) {
                self.model.updateCallParticipants(callParticipants)
                WebRTCClient.instance?.updateCallParticipant(callParticipants: callParticipants)
            }
        }
    }

    func callInquiry() {
        guard let callId = model.startCall?.callId else { return }
        Chat.sharedInstance.callInquery(.init(subjectId: callId)) { [weak self] callParticipants, _, _ in
            if let self = self, let callParticipants = callParticipants?.filter({ $0.userId != self.model.startCall?.clientDTO.userId }) {
                // update only call participants who not current user
                self.model.updateCallParticipants(callParticipants)
                WebRTCClient.instance?.updateCallParticipant(callParticipants: callParticipants)
            }
        }
    }

    func onCallEnd(_ callId: Int?) {
        endCallKitCall()
        model.setShowCallView(false)
        LogViewModel.printCallLogsFile()
        WebRTCClient.instance?.clearResourceAndCloseConnection()
        resetCall()
    }

    func onMuteParticipants(_ callParticipants: [CallParticipant]) {
        model.muteParticipants(callParticipants)
    }

    func onUNMuteParticipants(_ callParticipants: [CallParticipant]) {
        model.unmuteParticipants(callParticipants)
    }

    func onTurnVideoOnParticipants(_ callParticipants: [CallParticipant]) {
        model.turnOnVideoParticipants(callParticipants)
    }

    func onTurnVideoOffParticipants(_ callParticipants: [CallParticipant]) {
        model.turnOffVideoParticipants(callParticipants)
    }

    func onCallStartRecording(_ recorder: Participant) {
        model.setStartRecording(participant: recorder)
    }

    func onCallStopRecording(_ recorder: Participant) {
        model.setStopRecording(participant: recorder)
    }

    /// Setup UI and WEBRCT for new participant joined to the call
    func onCallParticipantJoined(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            addCallParicipant(callParticipant)
        }
    }

    /// Setup UI and WEBRCT for new participant joined to the call
    func onCallParticipantLeft(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            removeCallParticipant(callParticipant)
        }
    }

    func onCallParticipantSpeaking(_ callParticipant: CallParticipant) {
        model.setUserIsSpeaking(callParticipant)
    }

    func onCallParticipantStoppedSpeaking(_ callParticipant: CallParticipant) {
        model.setUserSoppedSpeaking(callParticipant)
    }

    func resetCall() {
        startCallTimer?.invalidate()
        startCallTimer = nil
        model = CallStateModel()
        WebRTCClient.instance = nil
    }

    func toggleSpeaker() {
        WebRTCClient.instance?.toggleSpeaker()
        model.toggleSpeaker()
    }

    func toggleMute() {
        guard let currentUserId = Chat.sharedInstance.userInfo?.id, let callId = model.startCall?.callId else { return }
        let oldIsMuteState = model.usersRTC.first(where: { $0.direction == .send && $0.isAudioTopic })?.isMute ?? true
        let newIsMuteState = !oldIsMuteState
        if oldIsMuteState {
            Chat.sharedInstance.unmuteCall(.init(callId: callId, userIds: [currentUserId])) { _, _, _ in
            }
        } else {
            Chat.sharedInstance.muteCall(.init(callId: callId, userIds: [currentUserId])) { _, _, _ in
            }
        }

        WebRTCClient.instance?.setMute(newIsMuteState)
        if let index = model.usersRTC.firstIndex(where: { $0.isAudioTopic && $0.direction == .send }), let callParticipant = model.usersRTC[index].callParticipant {
            if newIsMuteState {
                model.muteParticipants([callParticipant])
            } else {
                model.unmuteParticipants([callParticipant])
            }
        }
    }

    func toggleCamera() {
        guard let callId = model.startCall?.callId else { return }
        let isVideoOnOldState = model.usersRTC.first(where: { $0.direction == .send && $0.isVideoTopic })?.isVideoOn ?? false
        let isVideoOnNewState = !isVideoOnOldState
        if isVideoOnOldState {
            Chat.sharedInstance.turnOffVideoCall(.init(subjectId: callId)) { _, _, _ in
            }
        } else {
            Chat.sharedInstance.turnOnVideoCall(.init(subjectId: callId)) { _, _, _ in
            }
        }

        WebRTCClient.instance?.setCameraIsOn(isVideoOnNewState)
        if let index = model.usersRTC.firstIndex(where: { $0.isVideoTopic && $0.direction == .send }), let callParticipant = model.usersRTC[index].callParticipant {
            if isVideoOnNewState {
                model.turnOnVideoParticipants([callParticipant])
            } else {
                model.turnOffVideoParticipants([callParticipant])
            }
        }
    }

    func switchCamera(_ isFront: Bool) {
//        guard let localVideoRenderer = localVideoRenderer else{return}
//        GroupWebRTCClientNew.instance?.switchCameraPosition(renderer: localVideoRenderer)
    }

    func close() {
        WebRTCClient.instance?.clearResourceAndCloseConnection()
        LogViewModel.printCallLogsFile()
        resetCall()
    }

    func startTimer() {
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.model.setTimerString(self?.model.startCallDate?.getDurationTimerString())
            }
        }
    }

    func endCallKitCall() {
        AppDelegate.shared?.callMananger.endCall(model.uuid)
    }

    func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.model.setRecordingTimerString(self?.model.startRecodrdingDate?.getDurationTimerString())
            }
        }
    }

    func addCallParicipant(_ callParticipant: CallParticipant, direction: RTCDirection = .receive) {
        WebRTCClient.instance?.addCallParticipant(callParticipant, direction: direction)
        let addedTopics = WebRTCClient.instance?.usersRTC.filter { $0.topic == topics(callParticipant).topicVideo || $0.topic == topics(callParticipant).topicAudio }
        addedTopics?.forEach { userRTC in
            model.addUserRTC(userRTC)
        }
    }

    func removeCallParticipant(_ callParticipant: CallParticipant) {
        WebRTCClient.instance?.removeCallParticipant(callParticipant)
        model.usersRTC.filter { $0.topic == topics(callParticipant).topicVideo || $0.topic == topics(callParticipant).topicAudio }.forEach { userRTC in
            model.removeUserRTC(userRTC)
        }
    }

    private func topics(_ callParticipant: CallParticipant) -> (topicVideo: String, topicAudio: String) {
        return ("Vi-\(callParticipant.sendTopic)", "Vo-\(callParticipant.sendTopic)")
    }
}

// Implement WebRTCClientDelegate
extension CallState {
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {}

    func didReceiveData(data: Data) {}

    func didReceiveMessage(message: String) {}

    func didConnectWebRTC() {}

    func didDisconnectWebRTC() {}
}

/// Size of the each cell in different size like iPad vs iPhone.
extension CallState {
    var defaultCellHieght: CGFloat {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isMoreThanTwoParticipant = model.usersRTC.filter { $0.isVideoTopic }.count > 2
        let ipadHieghtForTwoParticipant = (UIScreen.main.bounds.height / 2) - 32
        let ipadSize = isMoreThanTwoParticipant ? 350 : ipadHieghtForTwoParticipant
        return isIpad ? ipadSize : 150
    }
}
