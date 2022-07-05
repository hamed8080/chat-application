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
    private (set) var threads :[Conversation]                   = []
    private (set) var isViewDisplaying                          = false
    private (set) var threadsTyping:[SystemEventTypes]          = []
    private (set) var hasNext:Bool                              = true
    
    mutating func hasNext(_ hasNext:Bool){
        self.hasNext = hasNext
    }
    
    mutating func preparePaginiation(){
        offset = count + offset
    }
    
    mutating func setThreads(threads:[Conversation]){
        self.threads = threads
        sort()
    }
    
    mutating func appendThreads(threads:[Conversation]){
        //remove older data to prevent duplicate on view
        self.threads.removeAll(where: { cashedThread in threads.contains(where: {cashedThread.id == $0.id }) })
        self.threads.append(contentsOf: threads)
        sort()
    }
    
    mutating func sort(){
        self.threads.sort(by: {$0.time ?? 0 > $1.time ?? 0})
        self.threads.sort(by: {$0.pin == true && $1.pin == false})
    }
    
    mutating func clear(){
        self.offset     = 0
        self.threads    = []
    }
	
	mutating func pinThread(_ thread:Conversation){
		threads.first(where: {$0.id == thread.id})?.pin = true
	}
    
	mutating func unpinThread(_ thread:Conversation){
		threads.first(where: {$0.id == thread.id})?.pin = false
	}
    
    mutating func muteUnMuteThread(_ threadId:Int?, isMute:Bool){
        if let threadId = threadId , let index = threads.firstIndex(where: {$0.id == threadId}) {
            threads[index].mute = isMute
        }        
    }
    
    mutating func removeThread(_ thread:Conversation){
        guard let index = threads.firstIndex(of: thread) else{return}
        threads.remove(at: index)
    }
    
    mutating func setViewAppear(appear:Bool){
        isViewDisplaying = appear
    }
    
    mutating func addNewMessageToThread(_ message:Message){
        if let index = threads.firstIndex(where: {$0.id == message.conversation?.id}){
            let thread = threads[index]
            thread.unreadCount = message.conversation?.unreadCount ?? 1
            thread.lastMessageVO = message
            thread.lastMessage   = message.message
        }
    }
    
    mutating func addTypingThread(_ event: SystemEventTypes)->Bool{
        
        if case .SYSTEM_MESSAGE(_, _, let id) = event, typingThreadIds.contains(where: {$0 == id}) == false{
            threadsTyping.append(event)
            return true
        }else{
            return false
        }
    }
    
    mutating func removeTypingThread(_ event:SystemEventTypes){
        if case .SYSTEM_MESSAGE(_, _, let id) = event, let index = typingThreadIds.firstIndex(where: { $0 == id }){
            threadsTyping.remove(at: index)
        }
    }
    
    var typingThreadIds:[Int?]{
        return threadsTyping.map{ event -> Int? in
            guard case .SYSTEM_MESSAGE(_, _, let id) = event else {return nil}
            return id
        }
    }
    
}

extension ThreadsModel{
    
    mutating func setupPreview(){
        appendThreads(threads: MockData.generateThreads())
    }
}
