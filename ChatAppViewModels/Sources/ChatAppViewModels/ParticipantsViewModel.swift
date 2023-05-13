//
//  ParticipantsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import ChatModels
import ChatAppModels
import ChatDTO
import ChatCore

public final class ParticipantsViewModel: ObservableObject {
    public var thread: Conversation?
    private var hasNext = true
    private var count = 15
    private var offset = 0
    private(set) var firstSuccessResponse = false
    private(set) var cancellableSet: Set<AnyCancellable> = []
    @Published public var isLoading = false
    @Published public private(set) var totalCount = 0
    @Published public private(set) var participants: [Participant] = []
    @Published public var searchText: String = ""
    public var searchType: SearchParticipantType = .name

    public init(thread: Conversation? = nil) {
        self.thread = thread
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: .threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                if case let .threadRemoveParticipants(response) = event {
                    withAnimation {
                        response.result?.forEach { participant in
                            self?.removeParticipant(participant)
                        }
                    }
                }
            }
            .store(in: &cancellableSet)
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .filter { $0.count >= 2 }
            .removeDuplicates()
            .sink { searchText in
                self.searchParticipants(searchText)
            }
            .store(in: &cancellableSet)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getParticipants()
        }
    }

    public func getParticipants() {
        isLoading = true
        ChatManager.activeInstance?.getThreadParticipants(.init(threadId: thread?.id ?? 0, offset: offset, count: count), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public func searchParticipants(_ searchText: String) {
        isLoading = true
        var req = ThreadParticipantsRequest(threadId: thread?.id ?? -1)
        switch searchType {
        case .name:
            req.name = searchText
        case .username:
            req.username = searchText
        case .cellphoneNumber:
            req.cellphoneNumber = searchText
        case .admin:
            req.admin = true
        }
        ChatManager.activeInstance?.getThreadParticipants(req, completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public var filtered: [Participant] {
        if !searchText.isEmpty {
            switch searchType {
            case .name:
                return participants.filter { $0.name?.contains(searchText) ?? false }
            case .username:
                return participants.filter { $0.username?.contains(searchText) ?? false }
            case .cellphoneNumber:
                return participants.filter { $0.cellphoneNumber?.contains(searchText) ?? false }
            case .admin:
                return participants.filter { $0.admin == true }
            }
        } else {
            return participants
        }
    }

    public func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getParticipants()
    }

    public func onServerResponse(_ response: ChatResponse<[Participant]>) {
        if let participants = response.result {
            firstSuccessResponse = true
            appendParticipants(participants: participants)
            hasNext = response.pagination?.hasNext ?? false
        }
        isLoading = false
    }

    public func onCacheResponse(_ response: ChatResponse<[Participant]>) {
        if let participants = response.result {
            appendParticipants(participants: participants)
            hasNext = response.pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    public func refresh() {
        clear()
        getParticipants()
    }

    public func clear() {
        offset = 0
        count = 15
        totalCount = 0
        participants = []
    }

    public func removePartitipant(_ participant: Participant) {
        guard let id = participant.id, let threadId = thread?.id else { return }
        ChatManager.activeInstance?.removeParticipants(.init(participantId: id, threadId: threadId)) { [weak self] response in
            if response.error == nil, let participant = response.result?.first {
                self?.removeParticipant(participant)
            }
        }
    }

    public func preparePaginiation() {
        offset = participants.count
    }

    public func appendParticipants(participants: [Participant]) {
        // remove older data to prevent duplicate on view
        self.participants.removeAll(where: { participant in participants.contains(where: { participant.id == $0.id }) })
        self.participants.append(contentsOf: participants)
    }

    public func removeParticipant(_ participant: Participant) {
        participants.removeAll(where: { $0.id == participant.id })
    }
}
