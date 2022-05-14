//
//  TagsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct TagsModel {
    
    private (set) var tags:[Tag]                                = []
    private (set) var isViewDisplaying                          = false
    private (set) var selectedTag:Tag?                          = nil
    
    mutating func clear(){
        self.tags    = []
    }
    
    mutating func setViewAppear(appear:Bool){
        isViewDisplaying = appear
    }
    
    mutating func setTags(tags:[Tag]){
        self.tags = tags
    }
    
    mutating func appendTags(tags:[Tag]){
        //remove older data to prevent duplicate on view
        self.tags.removeAll(where: { cashedThread in tags.contains(where: {cashedThread.id == $0.id }) })
        self.tags.append(contentsOf: tags)
    }
    
    mutating func setSelectedTag(tag:Tag?, isSelected:Bool){
        selectedTag = tag
    }
    
    mutating func removeTag(_ tag:Tag){
        tags.removeAll(where: {$0.id == tag.id })
    }
    
    mutating func editedTag(_ tag:Tag){
        let tag = Tag(id: tag.id, name: tag.name, owner: tag.owner, active: tag.active, tagParticipants: tags.first(where: {$0.id == tag.id})?.tagParticipants)
        removeTag(tag)
        appendTags(tags: [tag])
    }
    
    mutating func removeParticipants(_ tagId:Int,_ tagParticipants:[TagParticipant]){
        if var tag = tags.first(where: {$0.id == tagId}){
            tag.tagParticipants?.removeAll(where: { cached in tagParticipants.contains(where: {cached.id == $0.id}) })
            let tagParticipants = tag.tagParticipants
            let tag = Tag(id: tagId, name: tag.name, owner: tag.owner, active: tag.active, tagParticipants: tagParticipants)
            removeTag(tag)
            appendTags(tags: [tag])
        }
    }
    
    mutating func addParticipant(_ tagId:Int, _ participants:[TagParticipant]){
        if let tagIndex = tags.firstIndex(where: {$0.id == tagId}){
            tags[tagIndex].tagParticipants?.append(contentsOf: participants)
        }
    }
}

extension TagsModel{
    
    mutating func setupPreview(){
        appendTags(tags: MockData.generateTags())
    }
}
