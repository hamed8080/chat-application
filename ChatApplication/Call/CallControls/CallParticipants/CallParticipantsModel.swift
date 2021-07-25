//
//  CallParticipantsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct CallParticipantsModel {
    
    private (set) var callParticipants :[CallParticipant] = []
    
    mutating func setCallParticipants(callParticipants:[CallParticipant]){
        self.callParticipants = callParticipants
    }
    
    mutating func appendCallParticipants(callParticipants:[CallParticipant]){
        self.callParticipants.append(contentsOf: callParticipants)
    }
    
    mutating func clear(){
        self.callParticipants    = []
    }
}

extension CallParticipantsModel{
    
    mutating func setupPreview(){
        var t1 = CallParticipantRow_Previews.callParticipant
        t1.id = UUID().uuidString
        t1.participant?.name = "Hamed Hosseini"
        
        var t2 = CallParticipantRow_Previews.callParticipant
        t2.id = UUID().uuidString
        t2.participant?.name = "Masoud Amjadi"
        
        var t3 = CallParticipantRow_Previews.callParticipant
        t3.id = UUID().uuidString
        t3.participant?.name = "Pooria Pahlevani"
        
        appendCallParticipants(callParticipants: [t1 , t2, t3])
    }
}
