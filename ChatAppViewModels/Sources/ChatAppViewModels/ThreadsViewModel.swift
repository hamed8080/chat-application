//
//  ThreadsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import OrderedCollections
import SwiftUI
import ChatModels
import ChatAppModels
import ChatCore
import ChatDTO
import ChatAppExtensions

public final class ThreadsViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var toggleThreadContactPicker = false
    @Published public var toggle = false
    @AppStorage("Threads", store: UserDefaults.group) public var threadsData: Data?
    @Published public var showAddParticipants = false
    @Published public var showCreateDirectThread = false
    @Published public var showAddToTags = false
    @Published public var threads: OrderedSet<Conversation> = []
    @Published private(set) var tagViewModel = TagsViewModel()
    @Published public var activeCallThreads: [CallToJoin] = []
    public private(set) var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public private(set) var count = 15
    public private(set) var offset = 0
    @Published public var searchText: String = ""
    private(set) var hasNext: Bool = true
    public var archivedOffset: Int = 0
    public var selectedThraed: Conversation?
    public var archived: Bool = false
    public var folder: Tag?
    public var title: String = ""
    @Published public var selectedFilterThreadType: ThreadTypes?
    private var requests: [String: Any] = [:]
    private var searchRequests: [String: Any] = [:]

    public init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink(receiveValue: onChatEvent)
            .store(in: &cancelable)
        getThreads()
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.searchThreads(newValue)
            }
            .store(in: &cancelable)
    }

    private func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        case .thread(let threadEventTypes):
            onThreadEvent(threadEventTypes)
        case .call(let callEventTypes):
            onCallEvent(callEventTypes)
        default:
            break
        }
    }

    private func onParticipantEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .add(let chatResponse):
            onAddPrticipant(chatResponse)
        case .deleted(let chatResponse):
            onDeletePrticipant(chatResponse)
        default:
            break
        }
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {

        switch event {
        case .threads(let response):
            onThreads(response)
        case .created(let response):
            onCreate(response)
        case .deleted(let response):
            onDeleteThread(response)
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case .updatedInfo(let response):
            if let thread = response.result {
                updateThreadInfo(thread)
            }
        case .updatedUnreadCount(let response):
            if let index = threads.firstIndex(where: { $0.id == response.result?.threadId }) {
                threads[index].unreadCount = response.result?.unreadCount
                objectWillChange.send()
            }
        case .mute(let response):
            onMuteThreadChanged(mute: true, threadId: response.result)
        case .unmute(let response):
            onMuteThreadChanged(mute: false, threadId: response.result)
        case .archive(let response):
            onArchive(response)
        case .unArchive(let response):
            onUNArchive(response)
        case .changedType(let response):
            onChangedType(response)
        case .spammed(let response):
            onSpam(response)
        case .unreadCount(let response):
            onUnreadCounts(response)
        case .pin(let response):
            onPin(response)
        case .unpin(let response):
            onUNPin(response)
        default:
            break
        }
    }

    private func onCallEvent(_ event: CallEventTypes) {
        switch event {
        case let .callEnded(response):
            activeCallThreads.removeAll(where: { $0.callId == response?.result })
        case let .groupCallCanceled(response):
            activeCallThreads.append(.init(threadId: response.subjectId ?? -1, callId: response.result?.callId ?? -1))
        case let .callReceived(response):
            activeCallThreads.append(.init(threadId: response.result?.conversation?.id ?? -1, callId: response.result?.callId ?? -1))
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case .new(let chatResponse):
            onNewMessage(chatResponse)
        case .cleared(let chatResponse):
            onClear(chatResponse)
        default:
            break
        }
    }

    private func onCreate(_ response: ChatResponse<Conversation>) {
        if let thread = response.result {
            AppState.shared.showThread(thread: thread)
            appendThreads(threads: [thread])
        }
        isLoading = false
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = threads.firstIndex(where: { $0.id == message.conversation?.id }) {
            threads[index].time = response.result?.conversation?.time
            threads[index].unreadCount = (threads[index].unreadCount ?? 0) + 1
            threads[index].lastMessageVO = response.result
            threads[index].lastMessage = response.result?.message
            if threads[index].pin == false {
                sort()
            }
        }
    }

    private func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = threads.firstIndex(where: {$0.id == response.result?.id })  {
            threads[index].type = .publicGroup
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getThreads()
        } else if status == .connected, firstSuccessResponse == true {
            // After connecting again
            refreshThreadsUnreadCount()
        }
    }

    public func getThreads() {
        isLoading = true
        ChatManager.activeInstance?.conversation.get(.init(count: count, offset: offset, type: selectedFilterThreadType))
    }

    public func getArchivedThreads() {
        archived = true
        isLoading = true
        ChatManager.activeInstance?.conversation.get(.init(count: count, offset: archivedOffset, archived: true))
    }

    public func resetArchiveSettings() {
        archived = false
        archivedOffset = 0
        hasNext = true
        objectWillChange.send()
    }

    public func resetFolderSettings() {
        folder = nil
        hasNext = true
        objectWillChange.send()
    }

    public func getThreadsInsideFolder(_ folder: Tag) {
        self.folder = folder
        let threadIds = folder.tagParticipants?.compactMap(\.conversation?.id) ?? []
        getThreadsWith(threadIds)
    }

    public func getThreadsWith(_ threadIds: [Int]) {
        if threadIds.count == 0 { return }
        isLoading = true
        ChatManager.activeInstance?.conversation.get(.init(threadIds: threadIds))
    }

    public func searchThreads(_ text: String) {
        let req = ThreadsRequest(name: text, type: .publicGroup)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.conversation.get(req)
    }

    private func onSearch(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result, let uniqueId = response.uniqueId, searchRequests[uniqueId] != nil {
            appendThreads(threads: threads)
            searchRequests.removeValue(forKey: uniqueId)
        }
    }

    public var filtered: [Conversation] {
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

    public func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getThreads()
    }

    public func onThreads(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            firstSuccessResponse = true
            appendThreads(threads: threads)
            let hasNextValue = response.hasNext && !response.cache
            hasNext(hasNextValue)
            updateWidgetPreferenceThreads(threads)
        }
        isLoading = false
    }

    public func updateWidgetPreferenceThreads(_ threads: [Conversation]) {
        var storageThreads = (try? JSONDecoder().decode([Conversation].self, from: threadsData ?? Data())) ?? []
        storageThreads.append(contentsOf: threads)
        let data = try? JSONEncoder().encode(Array(Set(storageThreads)))
        threadsData = data
    }

    public func refresh() {
        clear()
        getThreads()
    }

    public func createThread(_ model: StartThreadResultModel) {
        isLoading = true
        let invitees = model.selectedContacts.map { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        }
        ChatManager.activeInstance?.conversation.create(.init(invitees: invitees, title: model.title, type: model.type, uniqueName: model.isPublic ? model.title : nil))
    }

    /// Create a thread and send a message without adding a contact.
    public func fastMessage(_ invitee: Invitee, _ message: String) {
        isLoading = true
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        ChatManager.activeInstance?.conversation.create(.init(invitees: [invitee], title: "", type: .normal, message: messageREQ))
    }

    public func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance?.
    }

    public func makeThreadPublic(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.changeType(.init(threadId: threadId, type: .publicGroup))
    }

    public func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        showAddParticipants.toggle()
    }

    public func addParticipantsToThread(_ contacts: [Contact]) {
        isLoading = true
        guard let threadId = selectedThraed?.id else { return }
        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.participant.add(req)
    }

    private func onAddPrticipant(_ response: ChatResponse<Conversation>) {
        if let thread = response.result {
            /// To navigate to the thread immediately after adding participants
            AppState.shared.showThread(thread: thread)
        }
        isLoading = false
    }

    private func onDeletePrticipant(_ response: ChatResponse<[Participant]>) {
        if let index = firstIndex(response.subjectId) {
            threads[index].participantCount = min(0, threads[index].participantCount ?? 0 - 1)
        }
        isLoading = false
    }

    public func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        showAddToTags.toggle()
    }

    public func hasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    public func preparePaginiation() {
        offset = count + offset
    }

    public func appendThreads(threads: [Conversation]) {
        threads.forEach { thread in
            if let oldThread = self.threads.first(where: { $0.id == thread.id }) {
                oldThread.updateValues(thread)
            } else {
                self.threads.append(thread)
            }
        }
        sort()
    }

    public func sort() {
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && $1.pin == false })
    }

    public func clear() {
        hasNext = false
        offset = 0
        count = 0
        threads = []
        firstSuccessResponse = false
    }

    public func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = isMute
        }
    }

    public func removeThread(_ thread: Conversation) {
        guard let index = threads.firstIndex(where: { $0.id == thread.id }) else { return }
        withAnimation {
            _ = threads.remove(at: index)
        }
    }

    public func delete(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.delete(.init(subjectId: threadId))
    }

    private func onDeleteThread(_ response: ChatResponse<Participant>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.leave(.init(threadId: threadId, clearHistory: true))
    }

    public func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.message.clear(.init(subjectId: threadId))
    }

    private func onClear(_ response: ChatResponse<Int>) {
        if let threadId = response.result, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.spam(.init(subjectId: threadId))
    }

    private func onSpam(_ response: ChatResponse<Contact>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        threads.firstIndex(where: { $0.id == threadId ?? -1 })
    }

    public func refreshThreadsUnreadCount() {
        let threadsIds = threads.compactMap(\.id)
        ChatManager.activeInstance?.conversation.unreadCount(.init(threadIds: threadsIds))
    }

    private func onUnreadCounts(_ response: ChatResponse<[String : Int]>) {
        response.result?.forEach { key, value in
            if let index = threads.firstIndex(where: { $0.id == Int(key) ?? -1 }) {
                threads[index].unreadCount = value
            }
        }
        isLoading = false
        if response.result?.count ?? 0 > 0 {
            withAnimation {
                objectWillChange.send()
            }
        }
    }

    public func updateThreadInfo(_ thread: Conversation) {
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

    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            objectWillChange.send()
        }
    }

    public func onMuteThreadChanged(mute: Bool, threadId: Int?) {
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = mute
            sort()
            objectWillChange.send()
        }
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
