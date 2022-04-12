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
    private (set) var isViewDisplaying              = false
    private (set) var signalMessageText:String?     = nil
    private (set) var isRecording:Bool              = false
    private (set) var replyMessage:Message?         = nil
    private (set) var forwardMessage:Message?       = nil
    private (set) var isInEditMode:Bool             = false
    private (set) var selectedMessages:[Message]    = []
    private (set) var editMessage:Message?          = nil
    private (set) var thread:Conversation?          = nil
    
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
        sort()
    }
    
    mutating func appendMessages(messages:[Message]){
        self.messages.append(contentsOf: filterNewMessagesToAppend(serverMessages: messages))
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
}

extension ThreadModel{
    
    mutating func setupPreview(){
        let m4 = UploadFileMessage(uploadFileUrl: URL(string: "http://sandbox.podspace.ir:8080/nzh/drive/downloadFile?hash=MGTCI6EZFAU4HO3G")!, textMessage: "Test")
        m4.messageType = MessageType.TEXT.rawValue
        appendMessages(messages: MockData.generateMessages())
    }
}
