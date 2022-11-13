//
//  ParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation
import SwiftUI

class ParticipantsViewModel: ObservableObject {
    private var thread: Conversation
    private var hasNext = true
    private var count = 15
    private var offset = 0

    @Published
    var isLoading = false

    @Published
    private(set) var totalCount = 0

    @Published
    private(set) var participants: [Participant] = []

    private(set) var firstSuccessResponse = false
    private(set) var cancellableSet: Set<AnyCancellable> = []

    init(thread: Conversation) {
        self.thread = thread
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { event in
                if case .threadRemoveParticipants(let removedParticipants) = event {
                    withAnimation {
                        removedParticipants.forEach { participant in
                            self.removeParticipant(participant)
                        }
                    }
                }
            }
            .store(in: &cancellableSet)
        getParticipants()
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .CONNECTED {
            offset = 0
            getParticipants()
        }
    }

    func getParticipants() {
        isLoading = true
        Chat.sharedInstance.getThreadParticipants(.init(threadId: thread.id ?? 0, offset: offset, count: count), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getParticipants()
    }

    func onServerResponse(_ participants: [Participant]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let participants = participants {
            firstSuccessResponse = true
            appendParticipants(participants: participants)
            hasNext = pagination?.hasNext ?? false
        }
        isLoading = false
    }

    func onCacheResponse(_ participants: [Participant]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let participants = participants {
            appendParticipants(participants: participants)
            hasNext = pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .CONNECTED {
            isLoading = false
        }
    }

    func refresh() {
        clear()
        getParticipants()
    }

    func clear() {
        offset = 0
        count = 15
        totalCount = 0
        participants = []
    }

    func setupPreview() {
        appendParticipants(participants: MockData.generateParticipants())
    }

    func removePartitipant(_ participant: Participant) {
        guard let id = participant.id else { return }
        Chat.sharedInstance.removeParticipants(.init(participantId: id, threadId: thread.id ?? 0)) { [weak self] participant, _, error in
            if error == nil, let participant = participant?.first {
                self?.removeParticipant(participant)
            }
        }
    }

    func preparePaginiation() {
        offset = participants.count
    }

    func appendParticipants(participants: [Participant]) {
        // remove older data to prevent duplicate on view
        self.participants.removeAll(where: { participant in participants.contains(where: { participant.id == $0.id }) })
        self.participants.append(contentsOf: participants)
    }

    func removeParticipant(_ participant: Participant) {
        participants.removeAll(where: { $0.id == participant.id })
    }
}
