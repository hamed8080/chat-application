//
//  ThreadsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ThreadsModel {
    
    private (set) var count                                     = 15
    private (set) var offset                                    = 0
    private (set) var totalCount                                = 0
    private (set) var threads :[Conversation]                   = []
    private (set) var isViewDisplaying                          = false
    private (set) var threadsTyping:[SystemEventModel]          = []
    
    func hasNext()->Bool{
        return threads.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = count + offset
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setThreads(threads:[Conversation]){
        self.threads = threads
    }
    
    mutating func appendThreads(threads:[Conversation]){
        self.threads.append(contentsOf: threads)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.threads    = []
    }
	
	mutating func pinThread(_ thread:Conversation){
		threads.first(where: {$0.id == thread.id})?.pin = true
	}
    
	mutating func unpinThread(_ thread:Conversation){
		threads.first(where: {$0.id == thread.id})?.pin = false
	}
    
    mutating func removeThread(_ thread:Conversation){
        guard let index = threads.firstIndex(of: thread) else{return}
        threads.remove(at: index)
    }
    
    mutating func setViewAppear(appear:Bool){
        isViewDisplaying = appear
    }
    
    mutating func addNewMessageToThread(_ event:MessageEventModel){
        if let index = threads.firstIndex(where: {$0.id == event.message?.conversation?.id}){
            let thread = threads[index]
            thread.unreadCount = (thread.unreadCount ?? 0) + 1
            thread.lastMessageVO = event.message
            thread.lastMessage   = event.message?.message
        }
    }
    
    mutating func addTypingThread(_ event:SystemEventModel){
        threadsTyping.append(event)       
    }
    
    mutating func removeTypingThread(_ event:SystemEventModel){
        if let index = threadsTyping.firstIndex(where: { $0.threadId == event.threadId }){
            threadsTyping.remove(at: index)
        }
    }
    
}

extension ThreadsModel{
    
    mutating func setupPreview(){
        let t1 = ThreadRow_Previews.thread
        t1.title = "Hamed Hosseini"
        t1.id = 1
        
        let t2 = ThreadRow_Previews.thread
        t2.title = "Masoud Amjadi"
        t2.id = 2
        
        let t3 = ThreadRow_Previews.thread
        t2.title = "Pod Group"
        t3.id = 3
        appendThreads(threads: [t1 , t2, t3])
    }
}
