//
//  CallControlsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct CallControlsModel {
    
    private (set) var callId:Int?                   = nil
    private (set) var isMute:Bool                   = true
    private (set) var isVideoOn:Bool                = false
    private (set) var isSpeakerOn:Bool              = false
    
    mutating func clear(){
 
    }
    
    mutating func toggleMute(){
        isMute.toggle()
    }
    
    mutating func toggleVideo(){
        isVideoOn.toggle()
    }
    
    mutating func setSpeaker(_ state:Bool){
        isSpeakerOn = state
    }
    
    mutating func setCallId(_ callId:Int){
        self.callId = callId
    }
    
    mutating func endCall(){
        callId = nil
        isMute = true
        isMute = false
    }

}

extension CallControlsModel{
    
    mutating func setupPreview(){
        
    }
}
