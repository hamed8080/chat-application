//
//  ThreadsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ThreadsModel {
    
    private (set) var count                   = 15
    private (set) var offset                  = 0
    private (set) var totalCount              = 0
    private (set) var threads :[Conversation] = []
    
    func hasNext()->Bool{
        return threads.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = threads.count
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
    
}
