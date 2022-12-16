//
//  CallViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/4/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

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
    var newSticker: StickerResponse? { get set }
    static func joinToCall(_ callId: Int)
    func startCall(thread: Conversation?, contacts: [Contact]?, isVideoOn: Bool, groupName: String)
    func sendSticker(_ sticker: CallSticker)
}

class CallViewModel: ObservableObject, CallStateProtocol {
    public static let shared: CallViewModel = .init()
    var uuid: UUID = .init()
    var startCall: StartCall?
    @Published var isLoading = false
    @Published var activeLargeCall: CallParticipantUserRTC?
    @Published var showCallView: Bool = false
    @Published var offlineParticipants: [Participant] = []
    @Published var newSticker: StickerResponse?
    var startCallDate: Date?
    var startCallTimer: Timer?
    var timerCallString: String?
    var isCallStarted: Bool { startCall != nil }
    var usersRTC: [CallParticipantUserRTC] { ChatManager.activeInstance.webrtc?.callParticipantsUserRTC ?? [] }
    var activeUsers: [CallParticipantUserRTC] { usersRTC.filter { $0.callParticipant.active == true } }
    var call: CreateCall?
    var callId: Int? { call?.callId ?? startCall?.callId }
    var startCallRequest: StartCallRequest?
    var answerType: AnswerType = .init(video: false, mute: true)
    var isSpeakerOn: Bool = false
    var cameraType: CameraType = .unknown
    var cancellableSet: Set<AnyCancellable> = []
    var isReceiveCall: Bool { call?.creator.id != AppState.shared.user?.id }
    var callTitle: String? { isReceiveCall ? call?.title : startCallRequest?.titleOfCalling }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(callEvent(_:)), name: callEventName, object: nil)
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
    }

    func startCall(thread: Conversation? = nil, contacts: [Contact]? = nil, isVideoOn: Bool, groupName: String = "group") {
        startCallRequest = .init(client: .init(video: isVideoOn), contacts: contacts, thread: thread, type: isVideoOn ? .videoCall : .voiceCall, groupName: groupName)
        guard let req = startCallRequest else { return }
        toggleCallView(show: true)
        if req.isGroupCall {
            ChatManager.activeInstance.requestGroupCall(req, initCreateCall)
        } else {
            ChatManager.activeInstance.requestCall(req, initCreateCall)
        }
        AppDelegate.shared?.callMananger.startCall(req.titleOfCalling, video: req.isVideoOn, uuid: uuid)
    }

    func recall(_ participant: Participant?) {
        guard let participant = participant, let callId = callId, let coreUserId = participant.coreUserId else { return }
        ChatManager.activeInstance.renewCallRequest(.init(invitees: [.init(id: "\(coreUserId)", idType: .coreUserId)], callId: callId)) { _ in }
    }

    func getParticipants() {
        getActiveParticipants()
        getThreadParticipants()
    }

    func getActiveParticipants() {
        guard let callId = callId else { return }
        isLoading = true
        ChatManager.activeInstance.activeCallParticipants(.init(subjectId: callId)) { [weak self] response in
            response.result?.forEach { callParticipant in
                if let callParticipantUserRTC = self?.usersRTC.first(where: { $0.callParticipant == callParticipant }) {
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
        ChatManager.activeInstance.getThreadParticipants(.init(threadId: threadId)) { [weak self] response in
            response.result?.forEach { participant in
                let isInAcitveUsers = self?.activeUsers.contains(where: { $0.callParticipant.participant == participant }) ?? false
                let isInOfflineUsers = self?.offlineParticipants.contains(where: { $0.id == participant.id }) ?? false
                if !isInAcitveUsers, !isInOfflineUsers {
                    self?.offlineParticipants.append(participant)
                }
            }
            self?.isLoading = false
        }
    }

    // Create call don't mean the call realy started. CallStarted Event is real one when a call realy accepted by at least one participant.
    private func initCreateCall(_ response: ChatResponse<CreateCall>) {
        call = response.result
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
        case let .callStarted(startCall):
            onCallStarted(startCall)
        case let .callCreate(createCall):
            onCallCreated(createCall)
        case let .callReceived(receieveCall):
            onReceiveCall(receieveCall)
        case .callDelivered:
            break
        case let .callEnded(callId):
            onCallEnd(callId)
        case let .groupCallCanceled(call):
            if call.participant?.id == AppState.shared.user?.id {
                onCallEnd(call.callId)
            }
        case let .callCanceled(canceledCall):
            onCallCanceled(canceledCall)
        case .callRejected:
            break
        case let .callParticipantJoined(callParticipants):
            onCallParticipantJoined(callParticipants)
        case let .callParticipantLeft(callParticipants):
            onCallParticipantLeft(callParticipants)
        case let .callParticipantMute(callParticipants):
            onMute(callParticipants)
        case let .callParticipantUnmute(callParticipants):
            onUNMute(callParticipants)
        case .callParticipantsRemoved:
            break
        case let .turnVideoOn(callParticipants):
            onVideoOn(callParticipants)
        case let .turnVideoOff(callParticipants):
            onVideoOff(callParticipants)
        case .callClientError:
            break
        case .callParticipantStartSpeaking:
            objectWillChaneWithAnimation()
        case .callParticipantStopSpeaking:
            objectWillChaneWithAnimation()
        case let .sticker(sticker):
            onCallSticker(sticker)
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
    func onCallCanceled(_: Call) {
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
        fetchCallParticipants(startCall)
        objectWillChaneWithAnimation()
    }

    func fetchCallParticipants(_ startCall: StartCall) {
        guard let callId = startCall.callId else { return }
        ChatManager.activeInstance.activeCallParticipants(.init(subjectId: callId)) { [weak self] response in
            response.result?.forEach { callParticipant in
                if let callParticipantUserRTC = self?.usersRTC.first(where: { $0.callParticipant == callParticipant }) {
                    callParticipantUserRTC.callParticipant.update(callParticipant)
                }
            }
            self?.objectWillChaneWithAnimation()
        }
    }

    func callInquiry() {
        guard let callId = startCall?.callId else { return }
        ChatManager.activeInstance.callInquery(.init(subjectId: callId)) { [weak self] response in
            response.result?.forEach { callParticipant in
                if let callParticipantUserRTC = self?.usersRTC.first(where: { $0.callParticipant == callParticipant }) {
                    callParticipantUserRTC.callParticipant.update(callParticipant)
                }
            }
            self?.objectWillChaneWithAnimation()
        }
    }

    func onCallEnd(_: Int?) {
        resetCall()
    }

    /// Setup UI and WEBRCT for new participant joined to the call
    func onCallParticipantLeft(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let participant = callParticipant.participant {
                offlineParticipants.append(participant)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onMute(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
                callParticipantUserRTC.callParticipant.mute = true
                callParticipantUserRTC.audioRTC.setTrackEnable(false)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onUNMute(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
                callParticipantUserRTC.callParticipant.mute = false
                callParticipantUserRTC.audioRTC.setTrackEnable(true)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onVideoOn(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
                callParticipantUserRTC.callParticipant.video = true
                callParticipantUserRTC.videoRTC.setTrackEnable(true)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onVideoOff(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            if let callParticipantUserRTC = usersRTC.first(where: { $0.callParticipant == callParticipant }) {
                callParticipantUserRTC.callParticipant.video = false
                callParticipantUserRTC.videoRTC.setTrackEnable(false)
            }
        }
        objectWillChaneWithAnimation()
    }

    func onCallParticipantJoined(_ callParticipants: [CallParticipant]) {
        callParticipants.forEach { callParticipant in
            offlineParticipants.removeAll(where: { $0.id == callParticipant.userId })
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
        LogViewModel.printCallLogsFile()
    }

    func toggleSpeaker() {
        ChatManager.activeInstance.webrtc?.toggleSpeaker()
        isSpeakerOn.toggle()
    }

    func toggleMute() {
        guard let currentUserId = ChatManager.activeInstance.userInfo?.id, let callId = startCall?.callId else { return }
        if usersRTC.first(where: { $0.isMe })?.callParticipant.mute == true {
            ChatManager.activeInstance.unmuteCall(.init(callId: callId, userIds: [currentUserId]))
        } else {
            ChatManager.activeInstance.muteCall(.init(callId: callId, userIds: [currentUserId]))
        }
    }

    func toggleCamera() {
        guard let callId = startCall?.callId else { return }
        if usersRTC.first(where: { $0.isMe })?.callParticipant.video == true {
            ChatManager.activeInstance.turnOffVideoCall(.init(subjectId: callId))
        } else {
            ChatManager.activeInstance.turnOnVideoCall(.init(subjectId: callId))
        }
    }

    func switchCamera() {
        ChatManager.activeInstance.webrtc?.switchCamera()
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
        ChatManager.activeInstance.webrtc?.addCallParticipants(callParticipants)
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
        ChatManager.activeInstance.cancelCall(.init(call: cancelCall))
        endCallKitCall()
    }

    func endCall() {
        endCallKitCall()
        if isCallStarted == false {
            cancelCall()
        } else {
            // TODO: realease microphone and camera at the moument and dont need to wait and get response from server
            if let callId = callId {
                ChatManager.activeInstance.endCall(.init(subjectId: callId)) { _ in }
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
        ChatManager.activeInstance.acceptCall(.init(callId: callId, client: .init(mute: true, video: false)))
        CallViewModel.shared.toggleCallView(show: true)
        CallViewModel.shared.answerType = AnswerType(video: false, mute: true)
        AppDelegate.shared.callMananger.callAnsweredFromCusomUI()
    }

    func sendSticker(_ sticker: CallSticker) {
        guard let callId = callId else { return }
        ChatManager.activeInstance.sendCallSticker(.init(callId: callId, stickers: [sticker]))
    }

    func onCallSticker(_ sticker: StickerResponse) {
        if sticker.participant.id != AppState.shared.user?.id {
            newSticker = sticker
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
                self?.newSticker = nil
            }
        }
    }
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
