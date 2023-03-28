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

final class ThreadsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var toggleThreadContactPicker = false
    @AppStorage("Threads", store: UserDefaults.group) var threadsData: Data?
    @Published var showAddParticipants = false
    @Published var showAddToTags = false
    @Published var threads: [Conversation] = []
    private(set) var cancellableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false
    private(set) var count = 15
    private(set) var offset = 0
    var searchText: String = ""
    private(set) var hasNext: Bool = true
    var archivedOffset: Int = 0
    var selectedThraed: Conversation?
    var archived: Bool = false
    var folder: Tag?
    var title: String = ""
    @Published var selectedFilterThreadType: ThreadTypes?

    init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: .threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: .messageNotificationName)
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
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case let .threadInfoUpdated(response):
            if let thread = response.result {
                updateThreadInfo(thread)
            }
        case let .threadUnreadCountUpdated(response):
            if let index = threads.firstIndex(where: { $0.id == response.result?.threadId }) {
                threads[index].unreadCount = response.result?.unreadCount
                objectWillChange.send()
            }
        case let .threadMute(response):
            onMuteThreadChanged(mute: true, threadId: response.result)
        case let .threadUnmute(response):
            onMuteThreadChanged(mute: false, threadId: response.result)
        default:
            break
        }
    }

    func onNewMessage(_ event: MessageEventTypes) {
        if case let .messageNew(response) = event, let index = threads.firstIndex(where: { $0.id == response.result?.conversation?.id }) {
            threads[index].time = response.result?.conversation?.time
            threads[index].unreadCount = (threads[index].unreadCount ?? 0) + 1
            threads[index].lastMessageVO = response.result
            threads[index].lastMessage = response.result?.message
            if threads[index].pin == false {
                sort()
            }
        }
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getThreads()
        } else if status == .connected, firstSuccessResponse == true {
            // After connecting again
            refreshThreadsUnreadCount()
        }
    }

    func getThreads() {
        isLoading = true
        ChatManager.activeInstance?.getThreads(.init(count: count, offset: offset, type: selectedFilterThreadType), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    func getArchivedThreads() {
        archived = true
        isLoading = true
        ChatManager.activeInstance?.getThreads(.init(count: count, offset: archivedOffset, archived: true), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    func resetArchiveSettings() {
        archived = false
        archivedOffset = 0
        hasNext = true
        objectWillChange.send()
    }

    func resetFolderSettings() {
        folder = nil
        hasNext = true
        objectWillChange.send()
    }

    func getThreadsInsideFolder(_ folder: Tag) {
        self.folder = folder
        let threadIds = folder.tagParticipants?.compactMap(\.conversation?.id) ?? []
        getThreadsWith(threadIds)
    }

    func getThreadsWith(_ threadIds: [Int]) {
        if threadIds.count == 0 { return }
        isLoading = true
        ChatManager.activeInstance?.getThreads(.init(threadIds: threadIds), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    var filtered: [Conversation] {
        if let folder = folder {
            return folder.tagParticipants?
                .compactMap(\.conversation?.id)
                .compactMap { id in threads.first { $0.id == id } }
                ?? []
        } else if searchText.isEmpty {
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
        isLoading = true
        let invitees = model.selectedContacts.map { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        }
        ChatManager.activeInstance?.createThread(.init(invitees: invitees, title: model.title, type: model.type, uniqueName: model.isPublic ? model.title : nil)) { [weak self] response in
            if let thread = response.result {
                AppState.shared.animateAndShowThread(thread: thread)
            }
            self?.isLoading = false
        }
    }

    func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance?.
    }

    func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        showAddParticipants.toggle()
    }

    func addParticipantsToThread(_ contacts: [Contact]) {
        isLoading = true
        guard let threadId = selectedThraed?.id else {
            return
        }

        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)

        ChatManager.activeInstance?.addParticipant(req) { [weak self] response in
            if let thread = response.result {
                // To navigate to the thread immediately after adding participants
                AppState.shared.animateAndShowThread(thread: thread)
            }
            self?.isLoading = false
        }
    }

    func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        showAddToTags.toggle()
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
        hasNext = false
        offset = 0
        count = 0
        threads = []
        firstSuccessResponse = false
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
        ChatManager.activeInstance?.deleteThread(.init(subjectId: threadId)) { [weak self] response in
            if response.error == nil {
                self?.removeThread(thread)
            }
        }
    }

    func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.leaveThread(.init(threadId: threadId, clearHistory: true)) { [weak self] response in
            if response.error == nil {
                self?.removeThread(thread)
            }
        }
    }

    func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.clearHistory(.init(subjectId: threadId)) { [weak self] response in
            if response.result != nil {
                self?.removeThread(thread)
            }
        }
    }

    func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.spamPvThread(.init(subjectId: threadId)) { _ in }
    }

    func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        threads.firstIndex(where: { $0.id == threadId ?? -1 })
    }

    func refreshThreadsUnreadCount() {
        let threadsIds = threads.compactMap(\.id)
        ChatManager.activeInstance?.getThreadsUnreadCount(.init(threadIds: threadsIds)) { [weak self] response in
            response.result?.forEach { key, value in
                if let index = self?.threads.firstIndex(where: { $0.id == Int(key) ?? -1 }) {
                    self?.threads[index].unreadCount = value
                }
            }
            self?.isLoading = false
            if response.result?.count ?? 0 > 0 {
                withAnimation {
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func updateThreadInfo(_ thread: Conversation) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].title = thread.title
            threads[index].partner = thread.partner
            threads[index].image = thread.image
            threads[index].metadata = thread.metadata
            threads[index].description = thread.description
            threads[index].type = thread.type
            threads[index].userGroupHash = thread.userGroupHash
            threads[index].time = thread.time
            threads[index].group = thread.group
            objectWillChange.send()
        }
    }

    func onLastMessageChanged(_ thread: Conversation) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            objectWillChange.send()
        }
    }

    func onMuteThreadChanged(mute: Bool, threadId: Int?) {
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = mute
            objectWillChange.send()
        }
    }
}
