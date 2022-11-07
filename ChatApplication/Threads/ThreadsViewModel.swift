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
    private(set) var callsToJoin: [Call] = []

    @Published
    private var threads: [Conversation] = []
    private(set) var hasNext: Bool = true
    let archived: Bool

    init(archived: Bool = false) {
        self.archived = archived
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap { $0.object as? MessageEventTypes }
            .sink(receiveValue: onMessageEvent)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .threadNew(let newThreads):
            appendThreads(threads: [newThreads])
        case .threadDeleted(threadId: let threadId, participant: _):
            if let thread = threads.first(where: { $0.id == threadId }) {
                removeThread(thread)
            }
        default:
            break
        }
    }

    func onMessageEvent(_ event: MessageEventTypes?) {
        if case .messageNew(let message) = event {
            addNewMessageToThread(message)
        }
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .CONNECTED {
            offset = 0
            getThreads()
        }
    }

    func getThreads() {
        isLoading = true
        Chat.sharedInstance.getThreads(.init(count: count, offset: offset, archived: archived), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    var filtered: [Conversation] {
        if searchText.isEmpty {
            return threads
        } else {
            return threads.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false }
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
            getActiveCallsListToJoin(threads.compactMap{$0.id})
        }
        isLoading = false

    }

    func onCacheResponse(_ threads: [Conversation]?, _ uniqueId: String?, _ pagination: Pagination?, _ error: ChatError?) {
        if let threads = threads {
            appendThreads(threads: threads)
            hasNext(pagination?.hasNext ?? false)
        }
        if isLoading, AppState.shared.connectionStatus != .CONNECTED {
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
        setupPreview()
    }

    func createThread(_ model: StartThreadResultModel) {
        centerIsLoading = true
        let invitees = model.selectedContacts?.map { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        }
        Chat.sharedInstance.createThread(.init(invitees: invitees, title: model.title, type: model.type)) { thread, _, _ in
            if let thread = thread {
                AppState.shared.selectedThread = thread
            }
            self.centerIsLoading = false
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

        let participants = contacts.compactMap { contact in
            AddParticipantRequest(userName: contact.linkedUser?.username ?? "", threadId: threadId)
        }

        Chat.sharedInstance.addParticipants(participants) { thread, _, _ in
            if let thread = thread {
                AppState.shared.selectedThread = thread
            }
            self.centerIsLoading = false
        }
    }

    func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        showAddToTags.toggle()
    }

    func threadAddedToTag(_ tag: Tag) {
        if let selectedThraed = selectedThraed {
            isLoading = true
            tagViewModel.addThreadToTag(tag: tag, thread: selectedThraed) { _, _ in
                self.isLoading = false
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
        // remove older data to prevent duplicate on view
        self.threads.removeAll(where: { cashedThread in threads.contains(where: { cashedThread.id == $0.id }) })
        self.threads.append(contentsOf: threads)
        sort()
    }

    func sort() {
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && $1.pin == false })
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
        guard let index = threads.firstIndex(of: thread) else { return }
        withAnimation {
            _ = threads.remove(at: index)
        }
    }

    func addNewMessageToThread(_ message: Message) {
        if let index = threads.firstIndex(where: { $0.id == message.conversation?.id }) {
            let thread = threads[index]
            thread.unreadCount = message.conversation?.unreadCount ?? 1
            thread.lastMessageVO = message
            thread.lastMessage = message.message
        }
    }

    func setArchiveThread(isArchive: Bool, threadId: Int?) {
        withAnimation {
            if self.archived, isArchive == false {
                threads.removeAll(where: { $0.id == threadId })
            }
        }
    }

    func getActiveCallsListToJoin(_ threadIds: [Int]) {
        Chat.sharedInstance.getCallsToJoin(.init(threadIds: threadIds)) { calls, _, _ in
            if let calls = calls {
                self.callsToJoin.append(contentsOf: calls)
            }
        }
    }

    func joinToCall(_ call: Call) {
        let callState = CallState.shared
        Chat.sharedInstance.acceptCall(.init(callId: call.id, client: .init(mute: true, video: false)))
        withAnimation(.spring()) {
            callState.model.setIsJoinCall(true)
            callState.model.setShowCallView(true)
        }
        CallState.shared.model.setAnswerWithVideo(answerWithVideo: false, micEnable: false)
        AppDelegate.shared.callMananger.callAnsweredFromCusomUI()
    }
}
