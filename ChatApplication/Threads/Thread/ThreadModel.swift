//
//  ThreadModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ThreadModel {
    
    private (set) var isEnded                       = false
    private (set) var count                         = 15
    private (set) var messages :[Message]           = []
    private (set) var isViewDisplaying              = false
    private (set) var signalMessageText:String?     = nil
    private (set) var isRecording:Bool              = false
    private (set) var replyMessage:Message?         = nil
    private (set) var forwardMessage:Message?       = nil
    private (set) var isInEditMode:Bool             = false
    private (set) var selectedMessages:[Message]    = []
    private (set) var editMessage:Message?          = nil
    private (set) var thread:Conversation?          = nil
    private (set) var showExportView:Bool           = false
    private (set) var exportFileUrl:URL?            = nil
    
    mutating func setEnded(){
        self.isEnded = true
    }
    
    mutating func appendMessages(messages:[Message]){
        if messages.count == 0{
            setEnded()
            return
        }
        self.messages.insert(contentsOf: filterNewMessagesToAppend(serverMessages: messages), at:0)
        sort()
    }
    
    /// Filter only new messages prevent conflict with cache messages
    mutating func filterNewMessagesToAppend(serverMessages:[Message])->[Message]{
        let ids = self.messages.map{$0.id}
        let newMessages = serverMessages.filter { message in
            !ids.contains { id in
                return id == message.id
            }
        }
        return newMessages
    }
    
    mutating func appendMessage(_ message:Message){
        self.messages.append(message)
        sort()
    }
    
    mutating func clear(){
        self.count      = 15
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
    
    mutating func sort(){
       messages = messages.sorted { m1, m2 in
           if let t1 = m1.time , let t2 = m2.time{
              return t1 < t2
           }else{
               return false
           }
        }
    }
    
    mutating func setViewAppear(appear:Bool){
        isViewDisplaying = appear
    }
    
    mutating func setSignalMessage(text:String?){
        self.signalMessageText = text
    }
    
    mutating func toggleIsRecording(){
        self.isRecording.toggle()
    }
    
    mutating func setReplyMessage(_ message:Message?){
        replyMessage = message
    }
    
    mutating func setForwardMessage(_ message:Message?){
        isInEditMode = message != nil
        forwardMessage = message
    }
    
    mutating func setIsInEditMode(_ isInEditMode:Bool){
        self.isInEditMode = isInEditMode
    }
    
    mutating func appendSelectedMessage(_ message:Message){
        selectedMessages.append(message)
    }
    
    mutating func removeSelectedMessage(_ message:Message){
        guard let index = selectedMessages.firstIndex(of: message) else{return}
        selectedMessages.remove(at: index)
    }
    
    mutating func setEditMessage(_ message:Message){
        self.editMessage = message
    }
    
    mutating func messageEdited(_ message:Message){
        messages.first(where: {$0.id == message.id})?.message = message.message
    }
    
    mutating func setThread(_ thread:Conversation?){
        self.thread = thread
    }
    
    mutating func setShowExportView(_ show:Bool, exportFileUrl:URL?){
        self.showExportView = show
        self.exportFileUrl = exportFileUrl
    }
}

extension ThreadModel{
    
    mutating func setupPreview(){    
        appendMessages(messages: MockData.generateMessages())
    }
}
