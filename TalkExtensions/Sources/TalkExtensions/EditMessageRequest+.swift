//
//  EditMessageRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import ChatDTO
import TalkModels

public extension EditMessageRequest {

    init(messageId: Int, model: SendMessageModel) {
        self = EditMessageRequest(threadId: model.threadId,
                                  messageType: .text,
                                  messageId: messageId,
                                  textMessage: model.textMessage)
    }
}
