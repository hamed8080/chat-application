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
    @Published
    var isLoading = false

    @Published
    var centerIsLoading = false

    @Published var toggleThreadContactPicker = false

    @AppStorage("Threads", store: UserDefaults.group) var threadsData: Data?

    @Published
    var showAddParticipants = false

    @Published
    var showAddToTags = false

    private(set) var cancellableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false

    @Published
    private(set) var tagViewModel = TagsViewModel()

    private(set) var count = 15
    private(set) var offset = 0
    var searchText: String = ""

    @Published
    var threadsRowVM: [ThreadViewModel] = []

    private(set) var hasNext: Bool = true
    let archived: Bool

    init(archived: Bool = false) {
        self.archived = archived
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)
        getThreads()
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threadNew(let newThreads):
            appendThreads(threads: [newThreads])
        case .threadDeleted(threadId: let threadId, participant: _):
            if let thread = threadsRowVM.first(where: { $0.thread.id == threadId }) {
                removeThreadVM(thread)
            }
        default:
            break
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
        Chat.sharedInstance.getThreads(.init(count: count, offset: offset, archived: archived), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    var filtered: [ThreadViewModel] {
        if searchText.isEmpty {
            return threadsRowVM.filter{ $0.thread.isArchive == archived }
        } else {
            return threadsRowVM.filter{ $0.thread.title?.lowercased().contains(searchText.lowercased()) ?? false && $0.thread.isArchive == archived }
        }
    }

    func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getThreads()
    }

    func onServerResponse(_ threads: [Conversation]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let threads = threads {
            firstSuccessResponse = true
            appendThreads(threads: threads)
            hasNext(pagination?.hasNext ?? false)
            updateWidgetPreferenceThreads(threads)
        }
        isLoading = false
    }

    func onCacheResponse(_ threads: [Conversation]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let threads = threads {
            appendThreads(threads: threads)
            hasNext(pagination?.hasNext ?? false)
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func updateWidgetPreferenceThreads(_ threads: [Conversation]) {
        guard let threadsData = threadsData else { return }
        var storageThreads = (try? JSONDecoder().decode([Conversation].self, from: threadsData)) ?? []
        storageThreads.append(contentsOf: threads)
        let data = try? JSONEncoder().encode(Array(Set(storageThreads)))
        self.threadsData = data
    }

    func refresh() {
        clear()
        getThreads()
    }

    func setupPreview() {
        appendThreads(threads: MockData.generateThreads(count: 10))
    }

    func createThread(_ model: StartThreadResultModel) {
        centerIsLoading = true
        let invitees = model.selectedContacts?.map { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        }
        Chat.sharedInstance.createThread(.init(invitees: invitees, title: model.title, type: model.type)) { [weak self] thread, _, _ in
            if let thread = thread {
                AppState.shared.selectedThread = thread
            }
            self?.centerIsLoading = false
        }
    }

    func searchInsideAllThreads(text: String) {
        // not implemented yet
        //        Chat.sharedInstance.
    }

    var selectedThraed: Conversation?
    func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        showAddParticipants.toggle()
    }

    func addParticipantsToThread(_ contacts: [Contact]) {
        centerIsLoading = true
        guard let threadId = selectedThraed?.id else {
            return
        }

        let contactIds = contacts.compactMap{ $0.id }
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)

        Chat.sharedInstance.addParticipant(req) { [weak self] thread, _, _ in
            if let thread = thread {
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
        threadsRowVM.sort(by: { $0.thread.time ?? 0 > $1.thread.time ?? 0 })
        threadsRowVM.sort(by: { $0.thread.pin == true && $1.thread.pin == false })
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
        guard let index = threadsRowVM.firstIndex(where: {$0.threadId == threadVM.threadId}) else { return }
        withAnimation {
            _ = threadsRowVM.remove(at: index)
        }
    }
}
