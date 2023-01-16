//
//  ThreadsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation
import SwiftUI

class ThreadsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var centerIsLoading = false
    @Published var toggleThreadContactPicker = false
    @AppStorage("Threads", store: UserDefaults.group) var threadsData: Data?
    @Published var showAddParticipants = false
    @Published var showAddToTags = false
    @Published var threads: [Conversation] = []
    @Published private(set) var tagViewModel = TagsViewModel()
    private(set) var cancellableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false
    private(set) var count = 15
    private(set) var offset = 0
    var searchText: String = ""
    private(set) var hasNext: Bool = true
    let archived: Bool
    var selectedThraed: Conversation?

    init(archived: Bool = false) {
        self.archived = archived
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: messageNotificationName)
            .compactMap { $0.object as? MessageEventTypes }
            .sink(receiveValue: onNewMessage)
            .store(in: &cancellableSet)
        getThreads()
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case let .threadNew(response):
            if let newThreads = response.result {
                appendThreads(threads: [newThreads])
            }
        case let .threadDeleted(response):
            if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
                removeThread(thread)
            }
        default:
            break
        }
    }

    func onNewMessage(_ event: MessageEventTypes) {
        if case let .messageNew(response) = event, let thread = threads.first(where: { $0.id == response.result?.conversation?.id }) {
            thread.time = response.result?.conversation?.time
            sort()
        }
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getThreads()
        }
    }

    func getThreads() {
        isLoading = true
        ChatManager.activeInstance.getThreads(.init(count: count, offset: offset, archived: archived), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    var filtered: [Conversation] {
        if searchText.isEmpty {
            return threads.filter { $0.isArchive == archived }
        } else {
            return threads.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false && $0.isArchive == archived }
        }
    }

    func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getThreads()
    }

    func onServerResponse(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            firstSuccessResponse = true
            appendThreads(threads: threads)
            hasNext(response.pagination?.hasNext ?? false)
            updateWidgetPreferenceThreads(threads)
        }
        isLoading = false
    }

    func onCacheResponse(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            appendThreads(threads: threads)
            hasNext(response.pagination?.hasNext ?? false)
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func updateWidgetPreferenceThreads(_ threads: [Conversation]) {
        var storageThreads = (try? JSONDecoder().decode([Conversation].self, from: threadsData ?? Data())) ?? []
        storageThreads.append(contentsOf: threads)
        let data = try? JSONEncoder().encode(Array(Set(storageThreads)))
        threadsData = data
    }

    func refresh() {
        clear()
        getThreads()
    }

    func createThread(_ model: StartThreadResultModel) {
        centerIsLoading = true
        let invitees = model.selectedContacts?.map { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        }
        ChatManager.activeInstance.createThread(.init(invitees: invitees, title: model.title, type: model.type)) { [weak self] response in
            if let thread = response.result {
                AppState.shared.selectedThread = thread
            }
            self?.centerIsLoading = false
        }
    }

    func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance.
    }

    func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        showAddParticipants.toggle()
    }

    func addParticipantsToThread(_ contacts: [Contact]) {
        centerIsLoading = true
        guard let threadId = selectedThraed?.id else {
            return
        }

        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)

        ChatManager.activeInstance.addParticipant(req) { [weak self] response in
            if let thread = response.result {
                // To navigate to the thread immediately after adding participants
                AppState.shared.selectedThread = thread
            }
            self?.centerIsLoading = false
        }
    }

    func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        showAddToTags.toggle()
    }

    func threadAddedToTag(_ tag: Tag) {
        if let selectedThraed = selectedThraed {
            isLoading = true
            tagViewModel.addThreadToTag(tag: tag, thread: selectedThraed) { [weak self] _, _ in
                self?.isLoading = false
            }
        }
    }

    func hasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    func preparePaginiation() {
        offset = count + offset
    }

    func appendThreads(threads: [Conversation]) {
        threads.forEach { thread in
            if let oldThread = self.threads.first(where: { $0.id == thread.id }) {
                oldThread.updateValues(thread)
            } else {
                self.threads.append(thread)
            }
        }
        sort()
    }

    func sort() {
        threads = threads
            .sorted(by: { $0.time ?? 0 > $1.time ?? 0 })
            .sorted(by: { $0.pin == true && $1.pin == false })
    }

    func clear() {
        offset = 0
        threads = []
    }

    func pinThread(_ thread: Conversation) {
        threads.first(where: { $0.id == thread.id })?.pin = true
    }

    func unpinThread(_ thread: Conversation) {
        threads.first(where: { $0.id == thread.id })?.pin = false
    }

    func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = isMute
        }
    }

    func removeThread(_ thread: Conversation) {
        guard let index = threads.firstIndex(where: { $0.id == thread.id }) else { return }
        withAnimation {
            _ = threads.remove(at: index)
        }
    }

    func delete(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance.deleteThread(.init(subjectId: threadId)) { [weak self] response in
            if response.error == nil {
                self?.removeThread(thread)
            }
        }
    }

    func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance.leaveThread(.init(threadId: threadId, clearHistory: true)) { [weak self] response in
            if response.error == nil {
                self?.removeThread(thread)
            }
        }
    }

    func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance.clearHistory(.init(subjectId: threadId)) { [weak self] response in
            if response.result != nil {
                self?.clear()
            }
        }
    }

    func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance.spamPvThread(.init(subjectId: threadId)) { _ in }
    }

    func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        threads.firstIndex(where: { $0.id == threadId ?? -1 })
    }
}
