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
    func onMuteChanged(_ response: ChatResponse<Int>)
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
        ChatManager.activeInstance.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func unmute(_ threadId: Int) {
        ChatManager.activeInstance.unmuteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread.mute?.toggle()
            objectWillChange.send()
        }
    }
}
