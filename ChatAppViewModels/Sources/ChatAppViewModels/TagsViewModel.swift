//
//  TagsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import ChatModels
import ChatCore
import SwiftUI
import ChatAppModels

public final class TagsViewModel: ObservableObject {
    @Published public var tags: [Tag] = []
    @Published public var selectedTag: Tag?
    @Published public var isLoading = false
    @Published public var showAddParticipants = false
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false

    public init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        getTagList()
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            getTagList()
        }
    }

    public func onServerResponse(_ response: ChatResponse<[Tag]>) {
        if let tags = response.result {
            firstSuccessResponse = true
            appendTags(tags: tags)
        }
        isLoading = false
    }

    public func onCacheResponse(_ response: ChatResponse<[Tag]>) {
        if let tags = response.result {
            appendTags(tags: tags)
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
    }

    public func getTagList() {
        ChatManager.activeInstance?.tagList(completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public func deleteTag(_ tag: Tag) {
        ChatManager.activeInstance?.deleteTag(.init(id: tag.id)) { [weak self] response in
            if let tag = response.result, let self = self {
                self.removeTag(tag)
            }
        }
    }

    public func refresh() {
        clear()
        getTagList()
    }

    public func clear() {
        tags = []
        selectedTag = nil
    }

    public func createTag(name: String) {
        isLoading = true
        ChatManager.activeInstance?.createTag(.init(tagName: name)) { [weak self] response in
            if let tag = response.result, let self = self {
                self.appendTags(tags: [tag])
            }
            self?.isLoading = false
        }
    }

    public func addThreadToTag(tag: Tag, threadId: Int?, onComplete: ((_ participants: [TagParticipant], _ success: Bool) -> Void)? = nil) {
        if let threadId = threadId {
            isLoading = true
            ChatManager.activeInstance?.addTagParticipants(.init(tagId: tag.id, threadIds: [threadId])) { [weak self] response in
                if let tagParticipants = response.result, let self = self {
                    self.addParticipant(tag.id, tagParticipants)
                    onComplete?(tagParticipants, response.error == nil)
                }
                self?.isLoading = false
            }
        }
    }

    public func toggleSelectedTag(tag: Tag, isSelected: Bool) {
        setSelectedTag(tag: tag, isSelected: isSelected)
    }

    public func editTag(tag: Tag) {
        ChatManager.activeInstance?.editTag(.init(id: tag.id, tagName: tag.name)) { [weak self] response in
            if let tag = response.result, let self = self {
                self.editedTag(tag)
            }
        }
    }

    public func deleteTagParticipant(_ tagId: Int, _ tagParticipant: TagParticipant) {
        ChatManager.activeInstance?.removeTagParticipants(.init(tagId: tagId, tagParticipants: [tagParticipant])) { [weak self] response in
            if let tagParticipants = response.result, let self = self {
                self.removeParticipants(tagId, tagParticipants)
            }
        }
    }

    public func appendTags(tags: [Tag]) {
        // remove older data to prevent duplicate on view
        tags.forEach { tag in
            if let oldIndex = self.tags.firstIndex(where: { $0.id == tag.id }) {
                self.tags[oldIndex] = tag
            } else {
                self.tags.append(tag)
            }
        }
    }

    public func setSelectedTag(tag: Tag?, isSelected _: Bool) {
        selectedTag = tag
    }

    public func removeTag(_ tag: Tag) {
        tags.removeAll(where: { $0.id == tag.id })
    }

    public func editedTag(_ tag: Tag) {
        let tag = Tag(id: tag.id, name: tag.name, active: tag.active, tagParticipants: tags.first(where: { $0.id == tag.id })?.tagParticipants)
        removeTag(tag)
        appendTags(tags: [tag])
    }

    public func removeParticipants(_ tagId: Int, _ tagParticipants: [TagParticipant]) {
        if let tag = tags.first(where: { $0.id == tagId }) {
            tag.tagParticipants?.removeAll(where: { cached in tagParticipants.contains(where: { cached.id == $0.id }) })
            let tagParticipants = tag.tagParticipants
            let tag = Tag(id: tagId, name: tag.name, active: tag.active, tagParticipants: tagParticipants)
            removeTag(tag)
            appendTags(tags: [tag])
        }
    }

    public func addParticipant(_ tagId: Int, _ participants: [TagParticipant]) {
        if let tagIndex = tags.firstIndex(where: { $0.id == tagId }) {
            tags[tagIndex].tagParticipants?.append(contentsOf: participants)
        }
    }
}
