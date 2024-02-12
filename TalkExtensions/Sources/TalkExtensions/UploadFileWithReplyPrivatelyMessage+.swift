//
//  UploadFileWithReplyPrivatelyMessage+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import ChatDTO
import TalkModels
import ChatModels

public extension UploadFileWithReplyPrivatelyMessage {

    convenience init?(imageItem: ImageItem, model: SendMessageModel) {
        guard var req = ReplyPrivatelyRequest(model: model) else { return nil }
        let imageReq = UploadImageRequest(imageItem: imageItem, model.userGroupHash)
        req.messageType = .podSpacePicture
        self.init(imageFileRequest: imageReq, thread: model.conversation)
        uniqueId = imageReq.uniqueId
        req.uniqueId = imageReq.uniqueId
        replyPrivatelyRequest = req
        messageType = .podSpacePicture
    }

    convenience init?(attachmentFile: AttachmentFile, model: SendMessageModel) {
        guard
            let url = attachmentFile.request as? URL,
            var req = ReplyPrivatelyRequest(model: model),
            let fileReq = UploadFileRequest(url: url, model.userGroupHash)
        else { return nil }
        req.messageType = .podSpaceFile
        self.init(uploadFileRequest: fileReq, thread: model.conversation)
        uniqueId = fileReq.uniqueId
        req.uniqueId = fileReq.uniqueId
        replyPrivatelyRequest = req
        messageType = .podSpaceFile
    }
}
