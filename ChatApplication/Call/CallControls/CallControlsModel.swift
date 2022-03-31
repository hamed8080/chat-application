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
    private (set) var isFrontCamera:Bool            = true
    
    mutating func setSpeaker(_ state:Bool){
        isSpeakerOn = state
    }
    
    mutating func setCallId(_ callId:Int){
        self.callId = callId
    }
    
    mutating func setMute(_ isMute:Bool){
        self.isMute = isMute
    }
    
    mutating func setCameraOn(_ isCameraOn:Bool){
        self.isVideoOn = isCameraOn
    }
    
    mutating func setIsFront(_ isFtont:Bool){
        self.isFrontCamera = isFtont
    }
    
    mutating func setIsVideoOn(_ isVideoOn:Bool){
        self.isVideoOn = isVideoOn
    }
    
    mutating func toggleIsFront(){
        self.isFrontCamera.toggle()
    }
    
    mutating func endCall(){
        callId    = nil
        isVideoOn = false
        isMute    = false
    }

}

extension CallControlsModel{
    
    mutating func setupPreview(){
        
    }
}
