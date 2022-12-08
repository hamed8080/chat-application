//
//  RecordingViewModel.swift
//  ChatApplication
//
//  Created by hamed on 12/4/22.
//

import FanapPodChatSDK
import Foundation
import SwiftUI

protocol RecordingProtocol {
    var callId: Int? { get set }
    var startRecodrdingDate: Date? { get set }
    var recorder: Participant? { get set }
    var isRecording: Bool { get set }
    var recordingTimerString: String? { get set }
    var recordingTimer: Timer? { get set }
    func onCallStartRecording(_ recorder: Participant?, _ uniqueId: String?, _ error: ChatError?)
    func onCallStopRecording(_ recorder: Participant?, _ uniqueId: String?, _ error: ChatError?)
    func startRecordingTimer()
    func callEvent(_ notification: NSNotification)
    func toggleRecording()
    func startRecording(_ callId: Int)
    func stopRecording(_ callId: Int)
}

class RecordingViewModel: ObservableObject, RecordingProtocol {
    var callId: Int?
    var isRecording: Bool = false
    var recorder: Participant?
    var startRecodrdingDate: Date?
    var recordingTimerString: String?
    var recordingTimer: Timer?

    init(callId: Int?) {
        self.callId = callId
        NotificationCenter.default.addObserver(self, selector: #selector(callEvent(_:)), name: CALL_EVENT_NAME, object: nil)
    }

    @objc func callEvent(_ notification: NSNotification) {
        guard let type = (notification.object as? CallEventTypes) else { return }
        if case let .startCallRecording(participant) = type {
            onCallStartRecording(participant)
        } else if case let .stopCallRecording(participant) = type {
            onCallStopRecording(participant)
        }
    }

    func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recordingTimerString = self?.startRecodrdingDate?.getDurationTimerString()
                self?.objectWillChange.send()
            }
        }
    }

    func toggleRecording() {
        guard let callId = callId else { return }
        if isRecording {
            stopRecording(callId)
        } else {
            startRecording(callId)
        }
    }

    func startRecording(_ callId: Int) {
        Chat.sharedInstance.startRecording(.init(subjectId: callId), onCallStartRecording)
    }

    func stopRecording(_ callId: Int) {
        Chat.sharedInstance.stopRecording(.init(subjectId: callId), onCallStopRecording)
    }

    func onCallStartRecording(_ recorder: Participant?, _ uniqueId: String? = nil, _ error: ChatError? = nil) {
        self.recorder = recorder
        isRecording = true
        startRecodrdingDate = Date()
        startRecordingTimer()
    }

    func onCallStopRecording(_ recorder: Participant?, _ uniqueId: String? = nil, _ error: ChatError? = nil) {
        isRecording = false
        self.recorder = nil
        startRecodrdingDate = nil
    }
}
