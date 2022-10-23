//
//  UploadFileMessage.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/27/21.
//

import Foundation
import FanapPodChatSDK

class UploadFileMessage:Message{
    
    var uploadFileRequest:UploadFileRequest
    
    init(uploadFileRequest:UploadFileRequest, textMessage:String = "") {
        self.uploadFileRequest = uploadFileRequest
        super.init(threadId: nil,
                   deletable: nil,
                   delivered: nil,
                   editable: nil,
                   edited: nil,
                   id: nil,
                   mentioned: nil,
                   message: textMessage,
                   messageType: MessageType.text,//only for show view in message list because 0 or nil rows don't render
                   metadata: nil,
                   ownerId: nil,
                   pinned: nil,
                   previousId: nil,
                   seen: nil,
                   systemMetadata: nil,
                   time: nil,
                   timeNanos: nil,
                   uniqueId: UUID().uuidString, // to draw unique row in swiftui it needed to fill this value. do not use id cause id is nil cannot be drawn row after two upload
                   conversation: nil,
                   forwardInfo: nil,
                   participant: nil,
                   replyInfo: nil)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
}
