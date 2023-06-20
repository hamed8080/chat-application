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
    public private(set) var selectedAssistant: [Assistant] = []
    public private(set) var canceableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    private var canLoadNextPage: Bool { !isLoading && hasNext }
    @Published public private(set) var assistants: [Assistant] = []
    @Published public var isLoading = false
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
        default:
            break
        }
    }

    private func onAssistants(_ response: ChatResponse<[Assistant]>) {
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
        isLoading = true
        ChatManager.activeInstance?.assistant.get(.init(count: count, offset: offset))
    }

    public func appendOrUpdateAssistant(_ assistants: [Assistant]) {
        // Remove all assistants that were cached, to prevent duplication.
        assistants.forEach { assistant in
            if let oldAssistant = self.assistants.first(where: { $0.participant?.id == assistant.participant?.id }) {
                oldAssistant.update(assistant)
            } else {
                self.assistants.append(assistant)
            }
        }
    }

    public func deactiveSelectedAssistants() {
        isLoading = true
        ChatManager.activeInstance?.assistant.deactive(.init(assistants: selectedAssistant))
    }

    public func deactive(indexSet: IndexSet) {
        let assistants = assistants.enumerated().filter { indexSet.contains($0.offset) }.map(\.element)
        assistants.forEach { assistant in
            selectedAssistant.append(assistant)
            deactiveSelectedAssistants()
        }
    }
}
