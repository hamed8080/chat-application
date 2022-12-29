//
//  TagsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

class TagsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var selectedTag: Tag?
    @Published var isLoading = false
    @Published var showAddParticipants = false
    private(set) var cancellableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false

    init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        getTagList()
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            getTagList()
        }
    }

    func onServerResponse(_ response: ChatResponse<[Tag]>) {
        if let tags = response.result {
            firstSuccessResponse = true
            appendTags(tags: tags)
        }
        isLoading = false
    }

    func onCacheResponse(_ tags: [Tag]?, _: String?, _: ChatError?) {
        if let tags = tags {
            appendTags(tags: tags)
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func getTagList() {
        ChatManager.activeInstance.tagList(completion: onServerResponse)
    }

    func getOfflineTags() {
        AppState.shared.cache.get(useCache: true, cacheType: .tags) { [weak self] (response: ChatResponse<[Tag]>) in
            if let tags = response.result {
                self?.appendTags(tags: tags)
            }
        }
    }

    func deleteTag(_ tag: Tag) {
        ChatManager.activeInstance.deleteTag(.init(id: tag.id)) { [weak self] response in
            if let tag = response.result, let self = self {
                self.removeTag(tag)
            }
        }
    }

    func refresh() {
        clear()
        getTagList()
    }

    func clear() {
        tags = []
        selectedTag = nil
    }

    func setupPreview() {
        appendTags(tags: MockData.generateTags())
    }

    func createTag(name: String) {
        isLoading = true
        ChatManager.activeInstance.createTag(.init(tagName: name)) { [weak self] response in
            if let tag = response.result, let self = self {
                self.appendTags(tags: [tag])
            }
            self?.isLoading = false
        }
    }

    func addThreadToTag(tag: Tag, thread: Conversation, onComplete: @escaping (_ participants: [TagParticipant], _ success: Bool) -> Void) {
        if let threadId = thread.id {
            isLoading = true
            ChatManager.activeInstance.addTagParticipants(.init(tagId: tag.id, threadIds: [threadId])) { [weak self] response in
                if let tagParticipants = response.result, let self = self {
                    self.addParticipant(tag.id, tagParticipants)
                    onComplete(tagParticipants, response.error == nil)
                }
                self?.isLoading = false
            }
        }
    }

    func toggleSelectedTag(tag: Tag, isSelected: Bool) {
        setSelectedTag(tag: tag, isSelected: isSelected)
    }

    func editTag(tag: Tag) {
        ChatManager.activeInstance.editTag(.init(id: tag.id, tagName: tag.name)) { [weak self] response in
            if let tag = response.result, let self = self {
                self.editedTag(tag)
            }
        }
    }

    func deleteTagParticipant(_ tagId: Int, _ tagParticipant: TagParticipant) {
        ChatManager.activeInstance.removeTagParticipants(.init(tagId: tagId, tagParticipants: [tagParticipant])) { [weak self] response in
            if let tagParticipants = response.result, let self = self {
                self.removeParticipants(tagId, tagParticipants)
            }
        }
    }

    func appendTags(tags: [Tag]) {
        // remove older data to prevent duplicate on view
        self.tags.removeAll(where: { cashedThread in tags.contains(where: { cashedThread.id == $0.id }) })
        self.tags.append(contentsOf: tags)
    }

    func setSelectedTag(tag: Tag?, isSelected _: Bool) {
        selectedTag = tag
    }

    func removeTag(_ tag: Tag) {
        tags.removeAll(where: { $0.id == tag.id })
    }

    func editedTag(_ tag: Tag) {
        let tag = Tag(id: tag.id, name: tag.name, active: tag.active, tagParticipants: tags.first(where: { $0.id == tag.id })?.tagParticipants)
        removeTag(tag)
        appendTags(tags: [tag])
    }

    func removeParticipants(_ tagId: Int, _ tagParticipants: [TagParticipant]) {
        if var tag = tags.first(where: { $0.id == tagId }) {
            tag.tagParticipants?.removeAll(where: { cached in tagParticipants.contains(where: { cached.id == $0.id }) })
            let tagParticipants = tag.tagParticipants
            let tag = Tag(id: tagId, name: tag.name, active: tag.active, tagParticipants: tagParticipants)
            removeTag(tag)
            appendTags(tags: [tag])
        }
    }

    func addParticipant(_ tagId: Int, _ participants: [TagParticipant]) {
        if let tagIndex = tags.firstIndex(where: { $0.id == tagId }) {
            tags[tagIndex].tagParticipants?.append(contentsOf: participants)
        }
    }
}
