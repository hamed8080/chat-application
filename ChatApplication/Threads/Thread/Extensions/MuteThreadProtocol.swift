//
//  MuteThreadProtocol.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import FanapPodChatSDK
import Foundation

protocol MuteThreadProtocol {
    func toggleMute()
    func mute(_ threadId: Int)
    func unmute(_ threadId: Int)
    func onMuteChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
}

extension ThreadViewModel: MuteThreadProtocol {
    func toggleMute() {
        if thread.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    func mute(_ threadId: Int) {
        Chat.sharedInstance.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func unmute(_ threadId: Int) {
        Chat.sharedInstance.unmuteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func onMuteChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.mute?.toggle()
            objectWillChange.send()
        }
    }
}
