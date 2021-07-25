//
//  ParticipantsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ParticipantsModel {
    
    private (set) var count                         = 15
    private (set) var offset                        = 0
    private (set) var totalCount                    = 0
    private (set) var participants :[Participant]   = []
    
    func hasNext()->Bool{
        return participants.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = participants.count
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setParticipants(participants:[Participant]){
        self.participants = participants
    }
    
    mutating func appendParticipants(participants:[Participant]){
        self.participants.append(contentsOf: participants)
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.participants    = []
    }
}

extension ParticipantsModel{
    
    mutating func setupPreview(){
        let t1 = ParticipantRow_Previews.participant
        t1.name = "Hamed Hosseini"
        t1.id = 1
        
        let t2 = ParticipantRow_Previews.participant
        t2.name = "Masoud Amjadi"
        t2.id = 2
        
        let t3 = ParticipantRow_Previews.participant
        t2.name = "Pooria Pahlevani"
        t3.id = 3
        appendParticipants(participants: [t1 , t2, t3])
    }
}
