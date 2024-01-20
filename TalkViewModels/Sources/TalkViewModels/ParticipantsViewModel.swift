//
//  ParticipantsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import ChatModels
import TalkModels
import ChatDTO
import ChatCore

public final class ParticipantsViewModel: ObservableObject {
    public weak var thread: Conversation?
    private var hasNext = true
    private var count = 15
    private var offset = 0
    private(set) var firstSuccessResponse = false
    @Published public var isLoading = false
    @Published public private(set) var participants: [Participant] = []
    @Published public private(set) var searchedParticipants: [Participant] = []
    @Published public var searchText: String = ""
    @Published public var searchType: SearchParticipantType = .name
    private var cancelable: Set<AnyCancellable> = []

    public init(thread: Conversation? = nil) {
        self.thread = thread
        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                self?.onParticipantEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.user.publisher(for: .user)
            .compactMap { $0.object as? UserEventTypes }
            .sink { [weak self] event in
                self?.onUserEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Any> }
            .sink { [weak self] event in
                self?.onError(event)
            }
            .store(in: &cancelable)
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                if searchText.count > 2 {
                    self?.searchParticipants(searchText.lowercased())
                } else {
                    self?.searchedParticipants.removeAll()
                }
            }
            .store(in: &cancelable)
    }


    private func onParticipantEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .participants(let chatResponse):
            onParticipants(chatResponse)
            onSearchedParticipants(chatResponse)
        case .deleted(let chatResponse):
            onDelete(chatResponse)
        case .setAdminRoleToUser(let response):
            onSetAdminRole(response)
        case .removeAdminRoleFromUser(let response):
            onRemoveAdminRole(response)
        default:
            break
        }
    }

    private func onUserEvent(_ event: UserEventTypes) {
        switch event {
        case .remove(let chatResponse):
            onRemoveRoles(chatResponse)
        case .setRolesToUser(let chatResponse):
            onSetRolesToUser(chatResponse)
        default:
            break
        }
    }

    private func onDelete(_ response: ChatResponse<[Participant]>) {
        if let participants = response.result {
            withAnimation {
                participants.forEach { participant in
                    /// We decrease the participant count in the ThreadsViewModel and because the thread in this class is a reference it will update automatically.
                    removeParticipant(participant)
                }
            }
        }
    }

    public func onAdded(_ participants: [Participant]) {
        withAnimation {
            self.participants.insert(contentsOf: participants, at: 0)
            animateObjectWillChange()
        }
    }

    public func getParticipants() {
        isLoading = true
        ChatManager.activeInstance?.conversation.participant.get(.init(threadId: thread?.id ?? 0, offset: offset, count: count))
    }

    public func searchParticipants(_ searchText: String) {
        isLoading = true
        var req = ThreadParticipantRequest(threadId: thread?.id ?? -1)
        switch searchType {
        case .name:
            req.name = searchText
        case .username:
            req.username = searchText
        case .cellphoneNumber:
            req.cellphoneNumber = searchText
        case .admin:
            req.admin = true
            req.name = searchText
        }
        RequestsManager.shared.append(prepend: "SearchParticipants", value: req)
        ChatManager.activeInstance?.conversation.participant.get(req)
    }

    public var sorted: [Participant] {
        participants.sorted(by: { ($0.auditor ?? false && !($1.auditor ?? false)) || (($0.admin ?? false) && !($1.admin ?? false)) })
    }

    public func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getParticipants()
    }

    public func onParticipants(_ response: ChatResponse<[Participant]>) {
        // FIXME: This bug should be fixed in the caching system as described in the text below.
        /// If we remove this line due to a bug in the Cache, we will get an incorrect participants list.
        /// For example, after a user leaves a thread, if the user updates their getHistory, the left participant will be shown in the list, which is incorrect.
        if !response.cache, let participants = response.result, response.subjectId == thread?.id {
            firstSuccessResponse = true
            appendParticipants(participants: participants)
            hasNext = response.hasNext
        }
        isLoading = false
    }

    public func onSearchedParticipants(_ response: ChatResponse<[Participant]>) {
        if response.value(prepend: "SearchParticipants") != nil, let participants = response.result {
            searchedParticipants.removeAll()
            searchedParticipants.append(contentsOf: participants)
        }
        isLoading = false
    }

    public func refresh() {
        clear()
        getParticipants()
    }

    public func clear() {
        offset = 0
        count = 15
        participants = []
    }

    public func removePartitipant(_ participant: Participant) {
        guard let id = participant.id, let threadId = thread?.id else { return }
        ChatManager.activeInstance?.conversation.participant.remove(.init(participantId: id, threadId: threadId))
    }

    public func makeAdmin(_ participant: Participant) {
        guard let id = participant.id, let threadId = thread?.id else { return }
        let req = RolesRequest(userRoles: [.init(userId: id, roles: Roles.adminRoles)], threadId: threadId)
        RequestsManager.shared.append(prepend: "REQUEST-TO-ADMIN-PARTICIPANT", value: req)
        ChatManager.activeInstance?.user.set(req)
//        ChatManager.activeInstance?.conversation.participant.addAdminRole(.init(participants: [.init(id: "\(participant.coreUserId ?? 0)", idType: .coreUserId)], conversationId: threadId))
    }

    public func removeAdminRole(_ participant: Participant) {
        guard let id = participant.id, let threadId = thread?.id else { return }
        ChatManager.activeInstance?.user.remove(RolesRequest(userRoles: [.init(userId: id, roles: Roles.adminRoles)], threadId: threadId))
//        ChatManager.activeInstance?.conversation.participant.removeAdminRole(.init(participants: [.init(id: "\(participant.coreUserId ?? 0)", idType: .coreUserId)], conversationId: threadId))
    }

    public func preparePaginiation() {
        offset = participants.count
    }

    public func appendParticipants(participants: [Participant]) {
        // remove older data to prevent duplicate on view
        self.participants.removeAll(where: { participant in participants.contains(where: { participant.id == $0.id }) })
        self.participants.append(contentsOf: participants)
    }

    public func onRemoveRoles(_ response: ChatResponse<[UserRole]>) {
        response.result?.forEach{ userRole in
            if response.subjectId == thread?.id,
               let participantId = userRole.id,
               let index = participants.firstIndex(where: {$0.id == participantId}),
               userRole.isAdminRolesChanged
            {
                participants[index].admin = false
            }
            animateObjectWillChange()
        }
    }

    public func onSetRolesToUser(_ response: ChatResponse<[UserRole]>) {
        response.result?.forEach{ userRole in
            if response.subjectId == thread?.id,
               let participantId = userRole.id,
               let index = participants.firstIndex(where: {$0.id == participantId}),
               userRole.isAdminRolesChanged
            {
                participants[index].admin = true
                animateObjectWillChange()
            }
        }

//        /// If an admin makes another participant admin the setter will not get a list of roles in the response.
        if response.pop(prepend: "REQUEST-TO-ADMIN-PARTICIPANT") != nil, response.error == nil {
            response.result?.forEach{ userRole in
                if let index = participants.firstIndex(where: {$0.id == userRole.id}) {
                    participants[index].admin = true
                    animateObjectWillChange()
                }
            }
        }
    }

    private func onSetAdminRole(_ response: ChatResponse<[AdminRoleResponse]>) {
        response.result?.forEach{ adminRole in
            if adminRole.hasError == nil, adminRole.hasError == false, let index = participants.firstIndex(where: {$0.id == adminRole.participant?.id}) {
                participants[index].admin = true
                animateObjectWillChange()
            }
        }
    }

    private func onRemoveAdminRole(_ response: ChatResponse<[AdminRoleResponse]>) {
        response.result?.forEach{ adminRole in
            if adminRole.hasError == nil, adminRole.hasError == false, let index = participants.firstIndex(where: {$0.id == adminRole.participant?.id}) {
                participants[index].admin = false
                animateObjectWillChange()
            }
        }
    }

    public func removeParticipant(_ participant: Participant) {
        participants.removeAll(where: { $0.id == participant.id })
    }

    public func onError(_ response: ChatResponse<Any>) {
        if response.error != nil, response.value(prepend: "SearchParticipants") != nil {
            searchedParticipants.removeAll()
        }
    }
}
