//
//  Message+.swift
//  ChatApplication
//
//  Created by hamed on 4/15/22.
//

import FanapPodChatSDK
import Foundation
import SwiftUI

extension Message {
    var messageTitle: String {
        message ?? metaData?.name ?? ""
    }

    var calculatedMaxAndMinWidth: CGFloat {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let maxDeviceSize: CGFloat = isIpad ? 420 : 320
        let messageWidth = messageTitle.widthOfString(usingFont: UIFont.systemFont(ofSize: 22)) + 16
        let calculatedWidth: CGFloat = min(messageWidth, maxDeviceSize)
        let maxWidth = max(128, calculatedWidth)
        return maxWidth
    }

    var isImage: Bool { messageType == .podSpacePicture || messageType == .picture }

    func updateMessage(message: Message) {
        deletable = message.deletable
        delivered = message.delivered
        editable = message.editable
        edited = message.edited
        id = message.id
        mentioned = message.mentioned
        self.message = message.message
        messageType = message.messageType
        metadata = message.metadata
        ownerId = message.ownerId
        pinned = message.pinned
        previousId = message.previousId
        seen = message.seen
        systemMetadata = message.systemMetadata
        threadId = message.threadId
        time = message.time
        timeNanos = message.timeNanos
        uniqueId = message.uniqueId
        conversation = message.conversation
        forwardInfo = message.forwardInfo
        participant = message.participant
        replyInfo = message.replyInfo
    }
}
