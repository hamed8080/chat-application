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
    func onPinChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
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
        Chat.sharedInstance.pinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func unpin(_ threadId: Int) {
        Chat.sharedInstance.unpinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func onPinChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.pin?.toggle()
            objectWillChange.send()
            threadsViewModel?.sort()
        }
    }
}
