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
    @Published var threadsRowVM: [ThreadViewModel] = []
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
            if let threadId = response.subjectId, let thread = threadsRowVM.first(where: { $0.thread.id == threadId }) {
                removeThreadVM(thread)
            }
        default:
            break
        }
    }

    func onNewMessage(_ event: MessageEventTypes) {
        if case let .messageNew(response) = event, let threadVM = threadsRowVM.first(where: { $0.threadId == response.result?.conversation?.id }) {
            threadVM.thread.time = response.result?.conversation?.time
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

    var filtered: [ThreadViewModel] {
        if searchText.isEmpty {
            return threadsRowVM.filter { $0.thread.isArchive == archived }
        } else {
            return threadsRowVM.filter { $0.thread.title?.lowercased().contains(searchText.lowercased()) ?? false && $0.thread.isArchive == archived }
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
            if let oldThreadVM = threadsRowVM.first(where: { $0.threadId == thread.id }) {
                oldThreadVM.updateThread(thread)
            } else {
                threadsRowVM.append(ThreadViewModel(thread: thread, threadsViewModel: self))
            }
        }
        sort()
    }

    func sort() {
        threadsRowVM = threadsRowVM
            .sorted(by: { $0.thread.time ?? 0 > $1.thread.time ?? 0 })
            .sorted(by: { $0.thread.pin == true && $1.thread.pin == false })
    }

    func clear() {
        offset = 0
        threadsRowVM = []
    }

    func pinThread(_ thread: Conversation) {
        threadsRowVM.first(where: { $0.thread.id == thread.id })?.thread.pin = true
    }

    func unpinThread(_ thread: Conversation) {
        threadsRowVM.first(where: { $0.thread.id == thread.id })?.thread.pin = false
    }

    func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = threadsRowVM.firstIndex(where: { $0.threadId == threadId }) {
            threadsRowVM[index].thread.mute = isMute
        }
    }

    func removeThreadVM(_ threadVM: ThreadViewModel) {
        guard let index = threadsRowVM.firstIndex(where: { $0.threadId == threadVM.threadId }) else { return }
        withAnimation {
            _ = threadsRowVM.remove(at: index)
        }
    }
}
