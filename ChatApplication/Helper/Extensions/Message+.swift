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
    var forwardMessage: ForwardMessage? { self as? ForwardMessage }
    var forwardCount: Int? { forwardMessage?.forwardMessageRequest.messageIds.count }
    var forwardTitle: String? { forwardMessage != nil ? "Forward **\(forwardCount ?? 0)** messages to **\(forwardMessage?.destinationThread.title ?? "")**" : nil }
    var messageTitle: String { message ?? metaData?.name ?? forwardTitle ?? "" }
    var markdownTitle: AttributedString { (try? AttributedString(markdown: messageTitle)) ?? AttributedString(messageTitle) }
    var uploadFile: UploadWithTextMessageProtocol? { self as? UploadWithTextMessageProtocol }
    var fileExtension: String? { uploadFile?.uploadFileRequest.fileExtension }
    var fileName: String? { uploadFile?.uploadFileRequest.fileName }
    var type: MessageType? { messageType ?? .unknown }
    var isTextMessageType: Bool { type == .text || isFileType }
    var currentUser: User? { ChatManager.activeInstance.userInfo ?? AppState.shared.user }
    var isMe: Bool { (ownerId ?? 0 == currentUser?.id ?? 0) || isUnsentMessage }
    var isUploadMessage: Bool { self is UploadWithTextMessageProtocol }
    /// Check id because we know that the message was successfully added in server chat.
    var isUnsentMessage: Bool { self is UnSentMessageProtocol && id == nil }

    var calculatedMaxAndMinWidth: CGFloat {
        let minWidth: CGFloat = isUnsentMessage ? 148 : isFileType ? 164 : 128
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let maxDeviceSize: CGFloat = isIpad ? 420 : 320
        let messageWidth = messageTitle.widthOfString(usingFont: UIFont.systemFont(ofSize: 22)) + 16
        let calculatedWidth: CGFloat = min(messageWidth, maxDeviceSize)
        let maxWidth = max(minWidth, calculatedWidth)
        return maxWidth
    }

    var isImage: Bool { messageType == .podSpacePicture || messageType == .picture }

    func updateMessage(message: Message) {
        deletable = message.deletable
        delivered = message.delivered
        seen = message.seen ?? seen
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

    var iconName: String {
        switch messageType {
        case .text:
            return "doc.text.fill"
        case .voice:
            return "play.circle.fill"
        case .picture:
            return "photo.on.rectangle.angled"
        case .video:
            return "play.rectangle.fill"
        case .sound:
            return "play.circle.fill"
        case .file:
            return fileExtIcon
        case .podSpacePicture:
            return "photo.on.rectangle.angled"
        case .podSpaceVideo:
            return "play.rectangle.fill"
        case .podSpaceSound:
            return "play.circle.fill"
        case .podSpaceVoice:
            return "play.circle.fill"
        case .podSpaceFile:
            return fileExtIcon
        case .link:
            return "link.circle.fill"
        case .endCall:
            return "phone.fill.arrow.down.left"
        case .startCall:
            return "phone.fill.arrow.up.right"
        case .sticker:
            return "face.smiling.fill"
        case .location:
            return "map.fill"
        case .participantJoin:
            return "person.crop.rectangle.badge.plus"
        case .participantLeft:
            return "door.right.hand.open"
        case .none:
            return "paperclip.circle.fill"
        case .some(.unknown):
            return "paperclip.circle.fill"
        }
    }

    var fileExtIcon: String {
        switch metaData?.file?.extension ?? fileExtension ?? "" {
        case ".mp4", ".avi", ".mkv":
            return "play.rectangle.fill"
        case ".mp3", ".m4a":
            return "play.circle.fill"
        case ".docx", ".pdf", ".xlsx", ".txt", ".ppt":
            return "doc.fill"
        case ".zip", ".rar", ".7z":
            return "doc.zipper"
        default:
            return "paperclip.circle.fill"
        }
    }

    var isFileType: Bool {
        let fileTypes: [MessageType] = [.voice, .picture, .video, .sound, .file, .podSpaceFile, .podSpacePicture, .podSpaceSound, .podSpaceVoice]
        return fileTypes.contains(messageType ?? .unknown)
    }
}
