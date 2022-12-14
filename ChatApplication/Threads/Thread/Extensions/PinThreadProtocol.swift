//
//  PinThreadProtocol.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import FanapPodChatSDK
import Foundation

protocol PinThreadViewModelProtocol {
    func togglePin()
    func pin(_ threadId: Int)
    func unpin(_ threadId: Int)
    func onPinChanged(_ response: ChatResponse<Int>)
}

extension ThreadViewModel: PinThreadViewModelProtocol {
    func togglePin() {
        if thread.pin == false {
            pin(threadId)
        } else {
            unpin(threadId)
        }
    }

    func pin(_ threadId: Int) {
        ChatManager.activeInstance.pinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func unpin(_ threadId: Int) {
        ChatManager.activeInstance.unpinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func onPinChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil {
            thread.pin?.toggle()
            objectWillChange.send()
            threadsViewModel?.sort()
        }
    }
}
