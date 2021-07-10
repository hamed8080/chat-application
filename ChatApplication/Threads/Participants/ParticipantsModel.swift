//
//  ParticipantsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ParticipantsModel {
    
    
    private (set) var connectionStatus:String?      = "Connecting ..."
    private (set) var count                         = 15
    private (set) var offset                        = 0
    private (set) var totalCount                    = 0
    private (set) var participants :[Participant]     = []
    
    func hasNext()->Bool{
        return participants.count < totalCount
    }
    
    mutating func setConnectionStatus(_ status:ConnectionStatus){
        if status == .CONNECTED{
            connectionStatus = ""
        }else{
            connectionStatus = String(describing: status) + " ..."
        }
    }
    
    mutating func preparePaginiation(){
        offset = participants.count
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setThreads(participants:[Participant]){
        self.participants = participants
    }
    
    mutating func appendThreads(participants:[Participant]){
        self.participants.append(contentsOf: participants)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.participants    = []
    }
}

//extension ParticipantsModel{
//    
//    mutating func setupPreview(){
//        let t1 = ThreadRow_Previews.thread
//        t1.title = "Hamed Hosseini"
//        t1.id = 1
//        
//        let t2 = ThreadRow_Previews.thread
//        t2.title = "Masoud Amjadi"
//        t2.id = 2
//        
//        let t3 = ThreadRow_Previews.thread
//        t2.title = "Pod Group"
//        t3.id = 3
//        appendThreads(threads: [t1 , t2, t3])
//    }
//}
