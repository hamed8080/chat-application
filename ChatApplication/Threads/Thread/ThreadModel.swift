//
//  ThreadModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ThreadModel {
    
    private (set) var count                         = 15
    private (set) var offset                        = 0
    private (set) var totalCount                    = 0
    private (set) var messages :[Message]           = []
    
    func hasNext()->Bool{
        return messages.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = messages.count
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setMessages(messages:[Message]){
        self.messages = messages
    }
    
    mutating func appendMessages(messages:[Message]){
        self.messages.append(contentsOf: messages)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.messages   = []
    }
	
	mutating func pinMessage(_ message:Message){
		messages.first(where: {$0.id == message.id})?.pinned = true
	}
    
	mutating func unpinMessage(_ message:Message){
		messages.first(where: {$0.id == message.id})?.pinned = false
	}
    
    mutating func deleteMessage(_ message:Message){
        guard let index = messages.firstIndex(of: message) else{return}
        messages.remove(at: index)
    }
}

extension ThreadModel{
    
    mutating func setupPreview(){
        let m1 = MessageRow_Previews.message
        m1.message = "Hamed Hosseini"
        m1.id = 1
        
        let m2 = MessageRow_Previews.message
        m2.message = "Masoud Amjadi"
        m2.id = 2
        
        let m3 = MessageRow_Previews.message
        m2.message = "Pod Group"
        m3.id = 3
        appendMessages(messages: [m1 , m2, m3])
    }
}
