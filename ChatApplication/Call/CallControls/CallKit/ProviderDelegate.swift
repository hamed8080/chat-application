//
//  ProviderDelegate.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/16/21.
//

import AVFAudio
import CallKit
import FanapPodChatSDK
import Foundation
import UIKit

class ProviderDelegate: NSObject {
    private let provider: CXProvider
    private let callManager: CallManager

    static let providerConfiguration: CXProviderConfiguration = {
        let appName = "CHATS"
        let config = CXProviderConfiguration()
        config.maximumCallsPerCallGroup = 1
        config.iconTemplateImageData = UIImage(named: "IconMask")?.pngData()
        config.ringtoneSound = "Ringtone.aif"
        config.supportedHandleTypes = [.phoneNumber]
        config.supportsVideo = true
        return config
    }()

    init(callManager: CallManager) {
        self.callManager = callManager
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool, completion: ((Error?) -> Void)? = nil) {
        let callUpdate = CXCallUpdate()
        callUpdate.hasVideo = hasVideo
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if error == nil {
                let call = CallItem(uuid: uuid)
                call.handle = handle

                self.callManager.addCall(call)
            }
            completion?(error)
        }
    }
}

extension ProviderDelegate: CXProviderDelegate {
    func providerDidReset(_: CXProvider) {}

    func provider(_: CXProvider, perform action: CXStartCallAction) {
        let call = CallItem(uuid: action.callUUID, isOutgoing: true)
        call.handle = action.handle.value
//        configureAudioSession()

        call.hasStartedConnectingDidChange = { [weak self] in
            self?.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectingDate)
        }
        call.hasConnectedDidChange = { [weak self] in
            self?.provider.reportOutgoingCall(with: call.uuid, connectedAt: call.connectDate)
        }
        call.startCall { success in
            if success {
                // Signal to the system that the action was successfully performed.
                action.fulfill()

                // Add the new outgoing call to the app's list of calls.
                self.callManager.addCall(call)
            } else {
                // Signal to the system that the action was unable to be performed.
                action.fail()
            }
        }
    }

    func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        // Retrieve the CallItem instance corresponding to the action's call UUID.
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        /*
         Configure the audio session but do not start call audio here.
         Call audio should not be started until the audio session is activated by the system,
         after having its priority elevated.
         */
//        configureAudioSession()

        // Trigger the call to be answered via the underlying network service.
        let callState = CallViewModel.shared
        if let receiveCall = callState.call {
            ChatManager.activeInstance.acceptCall(.init(callId: receiveCall.callId, client: .init(mute: !callState.answerType.mute, video: callState.answerType.video)))
        }
        call.answerIncomingCall()

        // Signal to the system that the action was successfully performed.
        action.fulfill()
    }

    func provider(_: CXProvider, perform action: CXEndCallAction) {
        // Retrieve the SpeakerboxCall instance corresponding to the action's call UUID
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        // Stop call audio when ending a call.
//        stopAudio()

        // Trigger the call to be ended via the underlying network service.
        call.endCall()

        // Signal to the system that the action was successfully performed.
        action.fulfill()

        // Remove the ended call from the app's list of calls.
        callManager.removeCall(call)
    }

    func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        // Retrieve the SpeakerboxCall instance corresponding to the action's call UUID
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }

        // Update the SpeakerboxCall's underlying hold state.
        call.isOnHold = action.isOnHold

        // Stop or start audio in response to holding or unholding the call.
        if call.isOnHold {
//            stopAudio()
        } else {
//            startAudio()
        }

        // Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    func provider(_: CXProvider, didActivate _: AVAudioSession) {
        print("Received", #function)
//        startAudio()
    }

    func provider(_: CXProvider, didDeactivate _: AVAudioSession) {
        print("Received", #function)
    }

    func provider(_: CXProvider, timedOutPerforming _: CXAction) {
        print("Timed out", #function)
    }
}
