//
//  StringEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/10/21.
//

import Foundation

import FanapPodChatSDK
extension String{
    
    func isTypingAnimationWithText(onStart:@escaping (String)->(),onChangeText:@escaping (String,Timer)->(),onEnd:@escaping ()->()){
        onStart(self)
        var count = 0
        var indicatorCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if count >= 100 {
                onEnd()
                timer.invalidate()
            }else{
                if indicatorCount == 3{
                    indicatorCount = 0
                }else{
                    indicatorCount = indicatorCount + 1
                }
                onChangeText("typing" + String(repeating: "•", count: indicatorCount), timer)
                count = count + 1
            }
        }
    }
    
    func signalMessage(signal:SystemEventTypes,onStart:@escaping (String)->(),onChangeText:@escaping (String,Timer)->(),onEnd:@escaping ()->()){
        onStart(self)
        var count = 0
        var indicatorCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if count >= 15 {
                onEnd()
                timer.invalidate()
            }else{
                if indicatorCount == 3{
                    indicatorCount = 0
                }else{
                    indicatorCount = indicatorCount + 1
                }
                if let typeString = getSystemTypeString(type: signal){
                    onChangeText(typeString + String(repeating: "•", count: indicatorCount), timer)
                }
                count = count + 1
            }
        }
    }
    
    func getSystemTypeString(type:SystemEventTypes)->String?{
        switch type {
        case .IS_TYPING:
            return "typing"
        case .RECORD_VOICE:
            return "recording audio"
        case .UPLOAD_PICTURE:
            return "uploading image"
        case .UPLOAD_VIDEO:
            return "uploading video"
        case .UPLOAD_SOUND:
            return "uploading sound"
        case .UPLOAD_FILE:
            return "uploading file"
        case .SERVER_TIME:
            return nil
        }
    }
}
