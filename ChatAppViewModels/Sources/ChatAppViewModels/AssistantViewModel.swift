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

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.firstSuccessResponse == false, status == .connected {
                self?.getAssistants()
            }
        }
        .store(in: &canceableSet)
        NotificationCenter.default.publisher(for: .assistant)
            .compactMap { $0.object as? AssistantEventTypes }
            .sink { [weak self] value in
                self?.isLoading = false
            }
            .store(in: &cancelable)
        getAssistants()
    }

    public func onServerResponse(_ response: ChatResponse<[Assistant]>) {
        if let assistants = response.result {
            firstSuccessResponse = true
            appendOrUpdateAssistant(assistants)
            hasNext = response.pagination?.hasNext ?? false
        }
        isLoading = false
    }

    public func onCacheResponse(_ response: ChatResponse<[Assistant]>) {
        if let assistants = response.result {
            appendOrUpdateAssistant(assistants)
            hasNext = response.pagination?.hasNext ?? false
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
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
