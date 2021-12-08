//
//  UploadFileMessage.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/27/21.
//

import Foundation
import FanapPodChatSDK

class UploadFileMessage:Message{
    
    var uploadFileUrl:URL
    
    init(uploadFileUrl:URL, textMessage:String = "") {
        self.uploadFileUrl = uploadFileUrl
        super.init(threadId: nil,
                   deletable: nil,
                   delivered: nil,
                   editable: nil,
                   edited: nil,
                   id: nil,
                   mentioned: nil,
                   message: textMessage,
                   messageType: MessageType.TEXT.rawValue,//only for show view in message list because 0 or nil rows don't render
                   metadata: nil,
                   ownerId: nil,
                   pinned: nil,
                   previousId: nil,
                   seen: nil,
                   systemMetadata: nil,
                   time: nil,
                   timeNanos: nil,
                   uniqueId: nil,
                   conversation: nil,
                   forwardInfo: nil,
                   participant: nil,
                   replyInfo: nil)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
}
