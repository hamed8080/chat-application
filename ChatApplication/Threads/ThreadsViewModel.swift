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
    private(set) var isFirstTimeConnectedRequestSuccess = false

    @Published
    private(set) var tagViewModel = TagsViewModel()

    @Published
    var searchInsideThreadString = ""

    private(set) var count = 15
    private(set) var offset = 0

    @Published
    private(set) var threads: [Conversation] = []
    private(set) var hasNext: Bool = true

    init() {
        AppState.shared.$connectionStatus
            .sink { status in
                if self.isFirstTimeConnectedRequestSuccess == false, status == .CONNECTED {
                    self.getThreads()
                }
            }
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { event in
                if case .messageNew(let message) = event {
                    self.addNewMessageToThread(message)
                }
            }
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { event in
                switch event {
                case .threadNew(let newThreads):
                    withAnimation {
                        self.appendThreads(threads: [newThreads])
                    }
                case .threadDeleted(threadId: let threadId, participant: _):
                    if let thread = self.threads.first(where: { $0.id == threadId }) {
                        self.removeThread(thread)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellableSet)
        getOfflineThreads()
    }

    func getThreads() {
        isLoading = true
        Chat.sharedInstance.getThreads(.init(count: count, offset: offset)) { [weak self] threads, _, pagination, _ in
            if let threads = threads {
                self?.isFirstTimeConnectedRequestSuccess = true
                self?.setThreads(threads: threads)
                self?.hasNext(pagination?.hasNext ?? false)
                if let data = try? JSONEncoder().encode(threads) {
                    self?.threadsData = data
                }
            }
            self?.isLoading = false
        }
    }

    func getOfflineThreads() {
        let req = ThreadsRequest(count: count, offset: offset)
        CacheFactory.get(useCache: true, cacheType: .getThreads(req)) { response in
            if let threads = response.cacheResponse as? [Conversation] {
                self.setThreads(threads: threads)
            }
        }
    }

    func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        Chat.sharedInstance.getThreads(.init(count: count, offset: offset)) { [weak self] threads, _, pagination, _ in
            if let threads = threads {
                self?.appendThreads(threads: threads)
                self?.hasNext(pagination?.hasNext ?? false)
            }
            self?.isLoading = false
        }
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

    func setThreads(threads: [Conversation]) {
        self.threads = threads
        //        sort()
    }

    func appendThreads(threads: [Conversation]) {
        // remove older data to prevent duplicate on view
        self.threads.removeAll(where: { cashedThread in threads.contains(where: { cashedThread.id == $0.id }) })
        self.threads.append(contentsOf: threads)
        //        sort()
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
        threads.remove(at: index)
    }

    func addNewMessageToThread(_ message: Message) {
        if let index = threads.firstIndex(where: { $0.id == message.conversation?.id }) {
            let thread = threads[index]
            thread.unreadCount = message.conversation?.unreadCount ?? 1
            thread.lastMessageVO = message
            thread.lastMessage = message.message
        }
    }
}
