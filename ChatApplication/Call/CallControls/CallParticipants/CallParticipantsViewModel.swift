//
//  CallParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation

class CallParticipantsViewModel: ObservableObject {
    var callId: Int
    var callParticipants: [CallParticipant] = []

    func clear() {
        callParticipants = []
    }

    @Published
    var isLoading = false

    private(set) var cencelableSet: Set<AnyCancellable> = []

    init(callId: Int) {
        self.callId = callId
    }

    func getParticipantsIfConnected() {
        AppState.shared.$connectionStatus.sink { status in
            if status == .connected {
                self.getActiveParticipants()
            }
        }
        .store(in: &cencelableSet)
    }

    func getActiveParticipants() {
        isLoading = true
        Chat.sharedInstance.activeCallParticipants(.init(subjectId: callId)) { [weak self] callParticipants, _, _ in
            self?.isLoading = false
            if let callParticipants = callParticipants {
                self?.callParticipants = callParticipants
            }
        }
    }

    func refresh() {
        clear()
        getActiveParticipants()
    }

    func recall(_ participant: CallParticipant) {
        guard let userId = participant.userId else { return }
        Chat.sharedInstance.renewCallRequest(.init(invitees: [.init(id: "\(userId)", idType: .userId)], callId: callId)) { _, _, _ in }
    }
}
