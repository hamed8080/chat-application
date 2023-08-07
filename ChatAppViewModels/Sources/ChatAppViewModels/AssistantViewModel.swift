//
//  AssistantViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import ChatModels
import ChatAppModels
import ChatCore
import ChatDTO

public final class AssistantViewModel: ObservableObject {
    private var count = 15
    private var offset = 0
    private var hasNext: Bool = true
    @Published public private(set) var selectedAssistant: [Assistant] = []
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var assistants: [Assistant] = []
    @Published public var isLoading = false
    @Published public var showAddAssistantSheet = false
    @Published public var isInSelectionMode = false
    private var cancelable: Set<AnyCancellable> = []
    private var requests: [String: Any] = [:]

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getAssistants()
            }
        }
        .store(in: &canceableSet)
        NotificationCenter.default.publisher(for: .assistant)
            .compactMap { $0.object as? AssistantEventTypes }
            .sink { [weak self] event   in
                self?.onAssistantEvent(event)
            }
            .store(in: &cancelable)
        getAssistants()
    }

    public func onAssistantEvent(_ event: AssistantEventTypes) {
        switch event {
        case .assistants(let chatResponse):
            onAssistants(chatResponse)
        case .register(let response):
            onRegisterAssistant(response)
        case .deactive(let response):
            onDeactiveAssistant(response)
        default:
            break
        }
    }

    public func onAssistants(_ response: ChatResponse<[Assistant]>) {
        if let assistants = response.result {
            appendOrUpdateAssistant(assistants)
            hasNext = response.hasNext
        }

        if !response.cache, let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            firstSuccessResponse = true
            isLoading = false
            requests.removeValue(forKey: uniqueId)
        }
    }

    public func getAssistants() {
        if isLoading { return }
        isLoading = true
        let req = AssistantsRequest(count: count, offset: offset)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.assistant.get(req)
    }

    public func appendOrUpdateAssistant(_ assistants: [Assistant]) {
        // Remove all assistants that were cached, to prevent duplication.
        assistants.forEach { assistant in
            if let oldAssistant = self.assistants.first(where: { $0.participant?.id == assistant.participant?.id }) {
                oldAssistant.update(assistant)
                oldAssistant.id = assistant.participant?.id
            } else {
                assistant.id = assistant.participant?.id
                self.assistants.append(assistant)
            }
        }
    }

    public func deactiveSelectedAssistants() {
        isLoading = true
        selectedAssistant.forEach { assistant in
            if assistant.assistant == nil {
                assistant.assistant = .init(id: "\(assistant.participant?.coreUserId ?? 0)", idType: .coreUserId)
            }
        }
        let req = DeactiveAssistantRequest(assistants: selectedAssistant)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.assistant.deactive(req)
    }

    public func deactive(indexSet: IndexSet) {
        let assistants = assistants.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        assistants.forEach { assistant in
            selectedAssistant.append(assistant)
            deactiveSelectedAssistants()
        }
    }

    public func onDeactiveAssistant(_ response: ChatResponse<[Assistant]>) {
        if let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            response.result?.forEach { assistant in
                assistants.removeAll(where: {$0.participant?.id == assistant.participant?.id})
            }
            requests.removeValue(forKey: uniqueId)
        }
    }

    public func registerAssistant(_ contact: Contact) {
        let assistant = Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        let req = RegisterAssistantsRequest(assistants: [.init(assistant: assistant, roles: Roles.adminRoles)])
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.assistant.register(req)
    }

    public func onRegisterAssistant(_ response: ChatResponse<[Assistant]>) {
        if let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            assistants.append(contentsOf: response.result ?? [])
            requests.removeValue(forKey: uniqueId)
        }
    }

    public func toggleSelectedAssistant(isSelected: Bool, assistant: Assistant) {
        if isSelected {
            selectedAssistant.append(assistant)
        } else {
            selectedAssistant.removeAll(where: { $0.participant?.id == assistant.participant?.id })
        }
    }
}
