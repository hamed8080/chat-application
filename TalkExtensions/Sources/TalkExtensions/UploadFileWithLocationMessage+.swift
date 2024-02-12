//
//  UploadFileWithLocationMessage+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import ChatDTO
import TalkModels
import ChatModels

public extension UploadFileWithLocationMessage {

    convenience init(location: LocationItem, model: SendMessageModel) {
        let req = LocationMessageRequest(item: location, model: model)
        self.init()
        uniqueId = req.uniqueId
        locationRequest = req
        messageType = .podSpacePicture
        threadId = model.threadId
        conversation = model.conversation
        time = UInt(Date().millisecondsSince1970)
        ownerId = model.meId
    }
}
