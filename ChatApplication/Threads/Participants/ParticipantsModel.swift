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
        //remove older data to prevent duplicate on view
        self.participants.removeAll(where: { participant in participants.contains(where: {participant.id == $0.id }) })
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
        appendParticipants(participants: MockData.generateParticipants())
    }
}
