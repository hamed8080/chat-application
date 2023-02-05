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
    var markdownTitle: AttributedString {
        guard let attributedString = try? NSMutableAttributedString(markdown: messageTitle) else { return AttributedString() }
        let title = attributedString.string
        title.matches(char: "@")?.forEach { match in
            let userName = title[Range(match.range, in: title)!]
            let sanitizedUserName = String(userName).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
            attributedString.addAttributes([NSAttributedString.Key.link: NSURL(string: "ShowUser:User?userName=\(sanitizedUserName)")!], range: match.range)
        }
        return AttributedString(attributedString)
    }

    var uploadFile: UploadWithTextMessageProtocol? { self as? UploadWithTextMessageProtocol }
    var fileExtension: String? { uploadFile?.uploadFileRequest.fileExtension }
    var fileName: String? { uploadFile?.uploadFileRequest.fileName }
    var type: MessageType? { messageType ?? .unknown }
    var isTextMessageType: Bool { type == .text || isFileType }
    var currentUser: User? { ChatManager.activeInstance?.userInfo ?? AppState.shared.user }
    var isMe: Bool { (ownerId ?? 0 == currentUser?.id ?? 0) || isUnsentMessage || isUploadMessage }
    var isUploadMessage: Bool { self is UploadWithTextMessageProtocol }
    /// Check id because we know that the message was successfully added in server chat.
    var isUnsentMessage: Bool { self is UnSentMessageProtocol && id == nil }

    var calculatedMaxAndMinWidth: CGFloat {
        let hasReplyMessage = replyInfo != nil
        let minWidth: CGFloat = isUnsentMessage ? 148 : isFileType ? 164 : hasReplyMessage ? 246 : 128
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        let maxDeviceSize: CGFloat = isIpad ? 420 : 320
        let messageWidth = messageTitle.widthOfString(usingFont: UIFont.systemFont(ofSize: 22)) + 16
        let timeWidth = time?.date.timeAgoSinceDatecCondence?.widthOfString(usingFont: UIFont.systemFont(ofSize: 16)) ?? 0
        let calculatedWidth: CGFloat = min(messageWidth, maxDeviceSize)
        let maxFooterAndMsg: CGFloat = max(timeWidth, calculatedWidth)
        let maxWidth = max(minWidth, maxFooterAndMsg)
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

    static let clockImage = UIImage(named: "clock")
    static let sentImage = UIImage(named: "single_chekmark")
    static let seenImage = UIImage(named: "double_checkmark")

    var footerStatus: (image: UIImage, fgColor: Color) {
        if seen == true {
            return (Message.seenImage!, .darkGreen.opacity(0.8))
        } else if delivered == true {
            return (Message.seenImage!, Color.gray)
        } else if id != nil {
            return (Message.sentImage!, .darkGreen.opacity(0.8))
        } else {
            return (Message.clockImage!, .darkGreen.opacity(0.8))
        }
    }
}
