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
    @Published
    var tags: [Tag] = []

    @Published
    var selectedTag: Tag? = nil

    @Published
    var isLoading = false

    @Published
    var showAddParticipants = false

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

    func onServerResponse(_ tags: [Tag]?, _ uniqueId: String?, _ error: ChatError?) {
        if let tags = tags {
            firstSuccessResponse = true
            appendTags(tags: tags)
        }
        isLoading = false
    }

    func onCacheResponse(_ tags: [Tag]?, _ uniqueId: String?, _ error: ChatError?) {
        if let tags = tags {
            appendTags(tags: tags)
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    func getTagList() {
        Chat.sharedInstance.tagList(completion: onServerResponse)
    }

    func getOfflineTags() {
        CacheFactory.get(useCache: true, cacheType: .tags) { [weak self] response in
            if let tags = response.cacheResponse as? [Tag] {
                self?.appendTags(tags: tags)
            }
        }
    }

    func deleteTag(_ tag: Tag) {
        Chat.sharedInstance.deleteTag(.init(id: tag.id)) { [weak self] tag, _, _ in
            if let tag = tag, let self = self {
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
        Chat.sharedInstance.createTag(.init(tagName: name)) { [weak self] tag, _, _ in
            if let tag = tag, let self = self {
                self.appendTags(tags: [tag])
            }
            self?.isLoading = false
        }
    }

    func addThreadToTag(tag: Tag, thread: Conversation, onComplete: @escaping (_ participants: [TagParticipant], _ success: Bool) -> ()) {
        if let threadId = thread.id {
            isLoading = true
            Chat.sharedInstance.addTagParticipants(.init(tagId: tag.id, threadIds: [threadId])) { [weak self] tagParticipants, _, error in
                if let tagParticipants = tagParticipants, let self = self {
                    self.addParticipant(tag.id, tagParticipants)
                    onComplete(tagParticipants, error == nil)
                }
                self?.isLoading = false
            }
        }
    }

    func toggleSelectedTag(tag: Tag, isSelected: Bool) {
        setSelectedTag(tag: tag, isSelected: isSelected)
    }

    func editTag(tag: Tag) {
        Chat.sharedInstance.editTag(.init(id: tag.id, tagName: tag.name)) { [weak self] tag, _, _ in
            if let tag = tag, let self = self {
                self.editedTag(tag)
            }
        }
    }

    func deleteTagParticipant(_ tagId: Int, _ tagParticipant: TagParticipant) {
        Chat.sharedInstance.removeTagParticipants(.init(tagId: tagId, tagParticipants: [tagParticipant])) { [weak self] tagParticipants, _, _ in
            if let tagParticipants = tagParticipants, let self = self {
                self.removeParticipants(tagId, tagParticipants)
            }
        }
    }

    func appendTags(tags: [Tag]) {
        // remove older data to prevent duplicate on view
        self.tags.removeAll(where: { cashedThread in tags.contains(where: { cashedThread.id == $0.id }) })
        self.tags.append(contentsOf: tags)
    }

    func setSelectedTag(tag: Tag?, isSelected: Bool) {
        selectedTag = tag
    }

    func removeTag(_ tag: Tag) {
        tags.removeAll(where: { $0.id == tag.id })
    }

    func editedTag(_ tag: Tag) {
        let tag = Tag(id: tag.id, name: tag.name, owner: tag.owner, active: tag.active, tagParticipants: tags.first(where: { $0.id == tag.id })?.tagParticipants)
        removeTag(tag)
        appendTags(tags: [tag])
    }

    func removeParticipants(_ tagId: Int, _ tagParticipants: [TagParticipant]) {
        if var tag = tags.first(where: { $0.id == tagId }) {
            tag.tagParticipants?.removeAll(where: { cached in tagParticipants.contains(where: { cached.id == $0.id }) })
            let tagParticipants = tag.tagParticipants
            let tag = Tag(id: tagId, name: tag.name, owner: tag.owner, active: tag.active, tagParticipants: tagParticipants)
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
