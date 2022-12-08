//
//  CallViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI
import WebRTC
//
//class ObservableCallParticipantUserRTC: CallParticipantUserRTC, ObservableObject {
//
//}

enum CameraType: String {
    case front
    case back
    case unknown
}

struct AnswerType {
    let video: Bool
    let mute: Bool
}

protocol CallStateProtocol {
    var startCallRequest: StartCallRequest? { get set }
    var usersRTC: [CallParticipantUserRTC] { get }
    var cameraType: CameraType { get set }
    var answerType: AnswerType { get set }
    var call: CreateCall? { get set }
    var callId: Int? { get }
    var callTitle: String? { get }
    var isCallStarted: Bool { get }
    static func joinToCall(_ callId: Int)
    func startCall(thread: Conversation?, contacts: [Contact]?, isVideoOn: Bool, groupName: String)
}

class CallViewModel: ObservableObject, CallStateProtocol {
    public static let shared: CallViewModel = .init()

    var uuid: UUID = .init()
    var startCall: StartCall?
    @Published
    var showCallView: Bool = false
    var startCallDate: Date?
    var startCallTimer: Timer?
    var timerCallString: String?
    var isCallStarted: Bool { startCall != nil }
    var usersRTC: [CallParticipantUserRTC] { WebRTCClient.instance?.callParticipantsUserRTC ?? [] }
    var activeUsers: [CallParticipantUserRTC] { usersRTC.filter { $0.callParticipant.active == true } }
    @Published
    var offlineParticipants: [Participant] = []
    var call: CreateCall?
    var callId: Int? { call?.callId ?? startCall?.callId }
    var startCallRequest: StartCallRequest?
    var answerType: AnswerType = AnswerType(video: false, mute: true)
    var isSpeakerOn: Bool = false
    var cameraType: CameraType = .unknown
    var cancellableSet: Set<AnyCancellable> = []
    var isReceiveCall: Bool { call?.creator.id != AppState.shared.user?.id }
    var callTitle: String? { isReceiveCall ? call?.title : startCallRequest?.titleOfCalling }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(callEvent(_:)), name: CALL_EVENT_NAME, object: nil)
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
    }

    func startCall(thread: Conversation? = nil, contacts: [Contact]? = nil, isVideoOn: Bool, groupName: String = "group") {
        startCallRequest = .init(client: .init(video: isVideoOn), contacts: contacts, thread: thread, type: isVideoOn ? .videoCall : .voiceCall, groupName: groupName)
        guard let req = startCallRequest else { return }
        toggleCallView(show: true)
        if req.isGroupCall {
            Chat.sharedInstance.requestGroupCall(req, initCreateCall)
        } else {
            Chat.sharedInstance.requestCall(req, initCreateCall)
        }
        AppDelegate.shared?.callMananger.startCall(req.titleOfCalling, video: req.isVideoOn, uuid: uuid)
    }

    func recall(_ participant: Participant?) {
        guard let participant = participant, let callId = callId, let coreUserId = participant.coreUserId else { return }
        Chat.sharedInstance.renewCallRequest(.init(invitees: [.init(id: "\(coreUserId)", idType: .coreUserId)], callId: callId)) { _, _, _ in }
    }

    func getParticipants() {
        getActiveParticipants()
        getThreadParticipants()
    }

    func getActiveParticipants() {
        guard let callId = callId else { return }
        isLoading = true
        Chat.sharedInstance.activeCallParticipants(.init(subjectId: callId)) { [weak self] callParticipants, _, _ in
            callParticipants?.forEach { callParticipant in
                if let callParticipantUserRTC = self?.usersRTC.first(where: {$0.callParticipant == callParticipant}){
                    callParticipantUserRTC.callParticipant.update(callParticipant)
                }
            }
            self?.isLoading = false
            self?.objectWillChaneWithAnimation()
        }
    }

    func getThreadParticipants() {
        guard let threadId = call?.conversation?.id else { return }
        isLoading = true
        Chat.sharedInstance.getThreadParticipants(.init(threadId: threadId)) { [weak self] participants, _, _, _ in
            participants?.forEach{ participant in
                if self?.activeUsers.contains(where: {$0.callParticipant.participant == participant}) == false {
                    self?.offlineParticipants.append(participant)
                }
            }
            self?.isLoading = false
        }
    }

    // Create call don't mean the call realy started. CallStarted Event is real one when a call realy accepted by at least one participant.
    private func initCreateCall(createCall: CreateCall?, uniqueId: String?, error: ChatError?) {
        call = createCall
    }

    func toggleCallView(show: Bool) {
        showCallView = show
        objectWillChange.send()
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if startCall != nil, status == .connected {
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
            if call.participant?.id == AppState.shared.user?.id {
                onCallEnd(call.callId)
            }
        case .callCanceled(let canceledCall):
            onCallCanceled(canceledCall)
        case .callRejected:
            break
        case .callParticipantJoined(let callParticipants):
            onCallParticipantJoined(callParticipants)
        case .callParticipantLeft(let callParticipants):
            onCallParticipantLeft(callParticipants)
        case .callParticipantMute(let callParticipants):
            onMute(callParticipants)
        case .callParticipantUnmute(let callParticipants):
            onUNMute(callParticipants)
        case .callParticipantsRemoved:
            break
        case .turnVideoOn(let callParticipants):
            onVideoOn(callParticipants)
        case .turnVideoOff(let callParticipants):
            onVideoOff(callParticipants)
        case .callClientError:
            break
        case .callParticipantStartSpeaking(_):
            objectWillChaneWithAnimation()
        case .callParticipantStopSpeaking(_):
            objectWillChaneWithAnimation()
        default:
            break
        }
    }

    func onCallCreated(_ createCall: CreateCall) {
        call = createCall
    }

    func onReceiveCall(_ createCall: CreateCall) {
        toggleCallView(show: true)
        call = createCall
        AppDelegate.shared.providerDelegate?.reportIncomingCall(uuid: uuid, handle: createCall.title ?? "", hasVideo: createCall.type == .videoCall, completion: nil)
    }

    // maybe reject or canceled after a time out
    func onCallCanceled(_ canceledCall: Call) {
        // don't remove showCallView == true leads to show callViewControls again in receiver of call who rejected call
        if showCallView {
            endCallKitCall()
            resetCall()
        }
    }

    func onCallStarted(_ startCall: StartCall) {
        self.startCall = startCall
        startCallDate = Date()
        startTimer()
        /// simulator File name
        let smFileName = TARGET_OS_SIMULATOR != 0 ? "webrtc_user_a.mp4" : nil
        let config = WebRTCConfig(startCall: startCall, isSendVideoEnabled: answerType.video || startCallRequest?.isVideoOn ?? false, fileName: smFileName)
        WebRTCClient.instance = WebRTCClient(config: config, delegate: self)
        let me = CallParticipant(sendTopic: config.topicSend ?? "", userId: AppState.shared.user?.id, mute: startCall.clientDTO.mute, video: startCall.clientDTO.video, participant: .init(name: "ME"))
        var users = [me]
        let otherUsers = startCall.otherClientDtoList?.filter { $0.userId != AppState.shared.user?.id }.compactMap { clientDTO in
            CallParticipant(sendTopic: clientDTO.topicSend, userId: clientDTO.userId, mute: clientDTO.mute, video: clientDTO.video)
        }
        users.append(contentsOf: otherUsers ?? [])
        addCallParicipants(users)
        WebRTCClient.instance?.createSession()
        fetchCallParticipants(startCall)
        objectWillChaneWithAnimation()
    }

    func fetchCallParticipants(_ startCall: StartCall) {
        guard let callId = startCall.callId else { return }
        Chat.sharedInstance.activeCallParticipants(.init(subjectId: callId)) { [weak self] callParticipants, _, _ in
            callParticipants?.forEach { callParticipant in
                if let callParticipantUserRTC = self?.usersRTC.first(where: {$0.callParticipant == callParticipant}){
                    callParticipantUserRTC.callParticipant.update(callParticipant)
                }
            }
            self?.objectWillChaneWithAnimation()
        }
    }

    func callInquiry() {
        guard let callId = startCall?.callId else { return }
        Chat.sharedInstance.callInquery(.init(subjectId: callId)) { [weak self] callParticipants, _, _ in
            callParticipants?.forEach { callParticipant in
                if let callParticipantUserRTC = self?.usersRTC.first(where: {$0.callParticipant == callParticipant}){
                    callParticipantUserRTC.callParticipant.update(callParticipant)
                }
            }
            self?.objectWillChaneWithAnimation()
        }
    }

    func onCallEnd(_ callId: Int?) {
        resetCall()
    }

    /// Setup UI and WEBRCT for new participant joined to the call
    func onCallParticipantLeft(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            WebRTCClient.instance?.removeCallParticipant(callParticipant)
            if let participant = callParticipant.participant {
                offlineParticipants.append(participant)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onMute(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: {$0.callParticipant == callParticipant}){
                callParticipantUserRTC.callParticipant.mute = true
                callParticipantUserRTC.audioRTC.setTrackEnable(false)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onUNMute(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: {$0.callParticipant == callParticipant}){
                callParticipantUserRTC.callParticipant.mute = false
                callParticipantUserRTC.audioRTC.setTrackEnable(true)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onVideoOn(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: {$0.callParticipant == callParticipant}){
                callParticipantUserRTC.callParticipant.video = true
                callParticipantUserRTC.videoRTC.setTrackEnable(true)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onVideoOff(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: {$0.callParticipant == callParticipant}){
                callParticipantUserRTC.callParticipant.video = false
                callParticipantUserRTC.videoRTC.setTrackEnable(false)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onCallParticipantJoined(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            offlineParticipants.removeAll(where: {$0.id == callParticipant.userId})
        }
        addCallParicipants(callParticipants)
        objectWillChaneWithAnimation()
    }

    func objectWillChaneWithAnimation() {
        withAnimation {
            objectWillChange.send()
        }
    }

    func resetCall() {
        call = nil
        startCall = nil
        toggleCallView(show: false)
        startCallTimer?.invalidate()
        startCallTimer = nil
        startCallRequest = nil
        endCallKitCall()
        WebRTCClient.instance?.clearResourceAndCloseConnection()
        WebRTCClient.instance = nil
        LogViewModel.printCallLogsFile()
    }

    func toggleSpeaker() {
        WebRTCClient.instance?.toggleSpeaker()
        isSpeakerOn.toggle()
    }

    func toggleMute() {
        guard let currentUserId = Chat.sharedInstance.userInfo?.id, let callId = startCall?.callId else { return }
        if usersRTC.first(where: { $0.isMe })?.callParticipant.mute == true {
            Chat.sharedInstance.unmuteCall(.init(callId: callId, userIds: [currentUserId]))
        } else {
            Chat.sharedInstance.muteCall(.init(callId: callId, userIds: [currentUserId]))
        }
        WebRTCClient.instance?.toggle()
    }

    func toggleCamera() {
        guard let callId = startCall?.callId else { return }
        if usersRTC.first(where: { $0.isMe })?.callParticipant.video == true {
            Chat.sharedInstance.turnOffVideoCall(.init(subjectId: callId))
        } else {
            Chat.sharedInstance.turnOnVideoCall(.init(subjectId: callId))
        }
        WebRTCClient.instance?.toggleCamera()
    }

    func switchCamera() {
//        guard let localVideoRenderer = localVideoRenderer else{return}
//        WebRTCClient.instance?.switchCameraPosition(renderer: localVideoRenderer)
    }

    func startTimer() {
        startCallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.timerCallString = (self?.startCallDate?.getDurationTimerString())
                self?.objectWillChaneWithAnimation()
            }
        }
    }

    func endCallKitCall() {
        AppDelegate.shared?.callMananger.endCall(uuid)
    }

    func addCallParicipants(_ callParticipants: [CallParticipant]? = nil) {
        guard let callParticipants = callParticipants else { return }
        WebRTCClient.instance?.addCallParticipants(callParticipants)
        objectWillChaneWithAnimation()
    }

    /// You can use this method to reject or cancel a call not startrd yet.
    func cancelCall() {
        toggleCallView(show: false)
        guard let callId = call?.callId,
              let creatorId = call?.creatorId,
              let type = call?.type,
              let isGroup = call?.group else { return }
        let cancelCall = Call(id: callId, creatorId: creatorId, type: type, isGroup: isGroup)
        Chat.sharedInstance.cancelCall(.init(call: cancelCall))
        endCallKitCall()
    }

    @Published
    var isLoading = false

    @Published
    var activeLargeCall: CallParticipantUserRTC? = nil

    func endCall() {
        endCallKitCall()
        if isCallStarted == false {
            cancelCall()
        } else {
            // TODO: realease microphone and camera at the moument and dont need to wait and get response from server
            if let callId = callId {
                Chat.sharedInstance.endCall(.init(subjectId: callId)) { _, _, _ in
                }
            }
        }
        resetCall()
    }

    func answerCall(video: Bool, audio: Bool) {
        if video {
            toggleCamera()
        }
        answerType = AnswerType(video: video, mute: !audio)
        AppDelegate.shared.callMananger.callAnsweredFromCusomUI()
    }

    static func joinToCall(_ callId: Int) {
        Chat.sharedInstance.acceptCall(.init(callId: callId, client: .init(mute: true, video: false)))
        CallViewModel.shared.toggleCallView(show: true)
        CallViewModel.shared.answerType = AnswerType(video: false, mute: true)
        AppDelegate.shared.callMananger.callAnsweredFromCusomUI()
    }
}

// Implement WebRTCClientDelegate
extension CallViewModel: WebRTCClientDelegate {
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {}

    func didReceiveData(data: Data) {}

    func didReceiveMessage(message: String) {}

    func didConnectWebRTC() {}

    func didDisconnectWebRTC() {}
}

/// Size of the each cell in different size like iPad vs iPhone.
extension CallViewModel {
    var defaultCellHieght: CGFloat {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let isMoreThanTwoParticipant = usersRTC.count > 2
        let ipadHieghtForTwoParticipant = (UIScreen.main.bounds.height / 2) - 32
        let ipadSize = isMoreThanTwoParticipant ? 350 : ipadHieghtForTwoParticipant
        return isIpad ? ipadSize : 150
    }
}
