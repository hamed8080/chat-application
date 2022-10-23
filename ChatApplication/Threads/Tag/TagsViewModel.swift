//
//  TagsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK
import Combine
import SwiftUI

class TagsViewModel:ObservableObject{
    
    @Published
    var isLoading = false
    
    @Published
    var centerIsLoading = false
    
    @Published
    var model = TagsModel()
    
    @Published var toggleThreadContactPicker = false
        
    @Published
    var showAddParticipants = false
    
    private (set) var cancellableSet: Set<AnyCancellable> = []
    private (set) var isFirstTimeConnectedRequestSuccess = false
    
    init() {
        AppState.shared.$connectionStatus.sink { status in
            if self.isFirstTimeConnectedRequestSuccess == false && status == .CONNECTED{
                self.getTagList()
            }
        }
        .store(in: &cancellableSet)
        getOfflineTags()
    }
    
    func getTagList(){
        Chat.sharedInstance.tagList { [weak self] tags, uniqueId, error in
            if let tags = tags , let self = self{
                self.isFirstTimeConnectedRequestSuccess = true
                self.model.setTags(tags: tags)
            }
            self?.isLoading = false
        }
    }
    
    func getOfflineTags(){
        CacheFactory.get(useCache: true, cacheType: .tags) { response in
            if let tags = response.cacheResponse as? [Tag]{
                self.model.setTags(tags: tags)
            }
        }
    }

    func deleteTag(_ tag:Tag){
        Chat.sharedInstance.deleteTag(.init(id: tag.id)) {  [weak self] tag, uniqueId, error in
            if let tag = tag , let self = self{
                self.model.removeTag(tag)
            }
        }
    }
    
    func refresh() {
        clear()
        getTagList()
    }
    
    func clear(){
        model.clear()
    }
    
    func setupPreview(){
        model.setupPreview()
    }
    
    func createTag(name:String){
        isLoading = true
        Chat.sharedInstance.createTag(.init(tagName: name)) {[weak self] tag, uniqueId, error in
            if let tag = tag, let self = self{
                self.model.appendTags(tags: [tag])
            }
            self?.isLoading = false
        }
    }
    
    func addThreadToTag(tag:Tag , thread:Conversation,onComplete:@escaping (_ participants:[TagParticipant],_ success:Bool)->()){
        if let threadId = thread.id{
            isLoading = true
            Chat.sharedInstance.addTagParticipants(.init(tagId: tag.id, threadIds: [threadId])) {[weak self] tagParticipants, uniqueId, error in
                if let tagParticipants = tagParticipants,let self = self{
                    self.model.addParticipant(tag.id,tagParticipants)
                    onComplete(tagParticipants,error == nil)
                }
                self?.isLoading = false
            }
        }
    }
    
    func toggleSelectedTag(tag:Tag , isSelected:Bool){
        model.setSelectedTag(tag: tag, isSelected:isSelected)
    }
    
    func editTag(tag:Tag){
        Chat.sharedInstance.editTag(.init(id: tag.id, tagName: tag.name)) {[weak self] tag, uniqueId, error in
            if let tag = tag, let self = self{
                self.model.editedTag(tag)
            }
        }
    }
    
    func deleteTagParticipant(_ tagId:Int, _ tagParticipant:TagParticipant){
        Chat.sharedInstance.removeTagParticipants(.init(tagId: tagId, tagParticipants: [tagParticipant])) { [weak self] tagParticipants, uinqueId, error in
            if let tagParticipants = tagParticipants, let self = self{
                self.model.removeParticipants(tagId, tagParticipants)
            }
        }
    }
    
}
