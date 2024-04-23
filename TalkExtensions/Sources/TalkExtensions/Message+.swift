//
//  Message+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import TalkModels
import ChatCore
import MapKit
import ChatModels
import ChatDTO
import Chat

public extension Message {
    static let textTypes = [ChatModels.MessageType.text, MessageType.link, MessageType.location]
    static let imageTypes = [ChatModels.MessageType.podSpacePicture, MessageType.picture]
    static let audioTypes = [ChatModels.MessageType.voice, .podSpaceSound, .sound, .podSpaceVoice]
    static let videoTypes = [ChatModels.MessageType.video, .podSpaceVideo, .video]
    static let fileTypes: [ChatModels.MessageType] = [.voice, .picture, .video, .sound, .file, .podSpaceFile, .podSpacePicture, .podSpaceSound, .podSpaceVoice, .podSpaceVideo]
    static let unreactionableTypes = [ChatModels.MessageType.endCall, .endCall, .participantJoin, .participantLeft]

    var forwardMessage: ForwardMessage? { self as? ForwardMessage }
    var forwardCount: Int? { forwardMessage?.forwardMessageRequest.messageIds.count }
    var messageTitle: String { message ?? "" }
    var isPublicLink: Bool { message?.contains(AppRoutes.joinLink) == true }
    var markdownTitle: NSAttributedString {
        let option: AttributedString.MarkdownParsingOptions = .init(allowsExtendedAttributes: false,
                                                                    interpretedSyntax: .inlineOnly,
                                                                    failurePolicy: .throwError,
                                                                    languageCode: nil,
                                                                    appliesSourcePositionAttributes: false)
        guard let mutableAttr = try? NSMutableAttributedString(markdown: messageTitle, options: option) else { return NSAttributedString() }
        mutableAttr.addUserColor(UIColor(named: "accent") ?? .orange)
        mutableAttr.addLinkColor(UIColor(named: "text_secondary") ?? .gray)
        return mutableAttr
    }
    
    var uploadFile: UploadWithTextMessageProtocol? { self as? UploadWithTextMessageProtocol }
    var fileExtension: String? { uploadFile?.uploadFileRequest?.fileExtension ?? uploadFile?.uploadImageRequest?.fileExtension }
    var uploadFileName: String? { uploadFile?.uploadFileRequest?.fileName ?? uploadFile?.uploadImageRequest?.fileName }
    var type: ChatModels.MessageType? { messageType ?? .unknown }
    var isTextMessageType: Bool { Message.textTypes.contains(messageType ?? .unknown) || isFileType }
    func isMe(currentUserId: Int?) -> Bool { (ownerId ?? 0 == currentUserId ?? 0) || isUnsentMessage || isUploadMessage }
    /// We should check metadata to be nil. If it has a value, it means that the message file has been successfully uploaded and sent to the chat server.
    var isUploadMessage: Bool { self is UploadWithTextMessageProtocol && metadata == nil }
    /// Check id because we know that the message was successfully added in server chat.
    var isUnsentMessage: Bool { self is UnSentMessageProtocol && id == nil }

    var isImage: Bool { Message.imageTypes.contains(messageType ?? .unknown) }
    var isAudio: Bool { Message.audioTypes.contains(messageType ?? .unknown) }
    var isVideo: Bool { Message.videoTypes.contains(messageType ?? .unknown) }
    var reactionableType: Bool { !Message.unreactionableTypes.contains(messageType ?? .unknown) }

    var fileHashCode: String { fileMetaData?.fileHash ?? fileMetaData?.file?.hashCode ?? "" }

    var fileURL: URL? {
        guard let url = url else { return nil }
        let chat = ChatManager.activeInstance
        return chat?.file.filePath(url) ?? chat?.file.filePathInGroup(url)
    }

    var url: URL? {
        let path = isImage == true ? Routes.images.rawValue : Routes.files.rawValue
        let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
        return URL(string: url)
    }

    var hardLink: URL? {
        guard
            let name = fileMetaData?.name,
            let diskURL = fileURL,
            let ext = fileMetaData?.file?.extension
        else { return nil }
        let hardLink = diskURL.appendingPathComponent(name).appendingPathExtension(ext)
        try? FileManager.default.linkItem(at: diskURL, to: hardLink)
        return hardLink
    }

    var tempURL: URL {
        let originalName = fileMetaData?.file?.originalName /// FileName + Extension
        var name: String? = nil
        if let fileName = fileMetaData?.file?.name, let ext = fileMetaData?.file?.extension {
            name = "\(fileName).\(ext)"
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name ?? originalName ?? "")
        return tempURL
    }

    func makeTempURL() async -> URL? {
        guard
            let diskURL = fileURL,
            FileManager.default.fileExists(atPath: diskURL.path)
        else { return nil }
        do {
            let data = try Data(contentsOf: diskURL)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    func updateMessage(message: Message) {
        deletable = message.deletable ?? deletable
        delivered = message.delivered ?? delivered ?? delivered
        seen = message.seen ?? seen ?? seen
        editable = message.editable ?? editable
        edited = message.edited ?? edited
        id = message.id ?? id
        mentioned = message.mentioned ?? mentioned
        self.message = message.message ?? self.message
        messageType = message.messageType ?? messageType
        metadata = message.metadata ?? metadata
        ownerId = message.ownerId ?? ownerId
        pinned = message.pinned ?? pinned
        previousId = message.previousId ?? previousId
        systemMetadata = message.systemMetadata ?? systemMetadata
        threadId = message.threadId ?? threadId
        time = message.time ?? time
        timeNanos = message.timeNanos ?? timeNanos
        uniqueId = message.uniqueId ?? uniqueId
        conversation = message.conversation ?? conversation
        forwardInfo = message.forwardInfo ?? forwardInfo
        participant = message.participant ?? participant
        replyInfo = message.replyInfo ?? replyInfo
    }

    var iconName: String? {
        messageType?.iconName ?? fileExtIcon
    }

    var fileStringName: String? {
        messageType?.fileStringName
    }

    var replyFileStringName: String? {
        replyInfo?.messageType?.fileStringName
    }

    var replyIconName: String? {
        replyInfo?.messageType?.iconName ?? fileExtIcon
    }

    var fileExtIcon: String {
        (fileMetaData?.file?.extension ?? fileExtension ?? "").systemImageNameForFileExtension
    }

    var isFileType: Bool {
        return Message.fileTypes.contains(messageType ?? .unknown)
    }

    var mapCoordinate: Coordinate? {
        guard
            let array = fileMetaData?.mapLink?.replacingOccurrences(of: Routes.baseMapLink.rawValue, with: "").split(separator: ","),
            let lat = Double(String(array[0])),
            let lng = Double(String(array[1]))
        else { return nil }
        return Coordinate(lat: lat, lng: lng)
    }

    var coordinate: Coordinate? {
        guard let latitude = fileMetaData?.latitude, let longitude = fileMetaData?.longitude else { return nil }
        return Coordinate(lat: latitude, lng: longitude)
    }

    var neshanURL: URL? {
        guard let coordinate = mapCoordinate else { return nil }
        return URL(string: "https://neshan.org/maps/@\(coordinate.lat),\(coordinate.lng),18.1z,0p")
    }

    var appleMapsURL: URL? {
        guard let coordinate = mapCoordinate else { return nil }
        return URL(string: "maps://?q=\(message ?? "")&ll=\(coordinate.lat),\(coordinate.lng)")
    }

    static let textDirectionMark = Language.isRTL ? "\u{200f}" : "\u{200e}"

    func addOrRemoveParticipantString(meId: Int?) -> String? {
        guard let requestType = addRemoveParticipant?.requestTypeEnum else { return nil }
        let isMe = participant?.id == meId
        let effectedName = addRemoveParticipant?.participnats?.first?.name ?? ""
        let participantName = participant?.name ?? ""
        let effectedParticipantsName = addRemoveParticipant?.participnats?.compactMap{$0.name}.joined(separator: ", ") ?? ""
        switch requestType {
        case .leaveThread:
            return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.left", bundle: Language.preferedBundle, comment: ""), participantName)
        case .joinThread:
            return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.joined", bundle: Language.preferedBundle, comment: ""), participantName)
        case .removedFromThread:
            if isMe {
                return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removedByMe", bundle: Language.preferedBundle, comment: ""), effectedName)
            } else {
                return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removed", bundle: Language.preferedBundle, comment: ""), participantName, effectedName)
            }
        case .addParticipant:
            if isMe {
                return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.addedByMe", bundle: Language.preferedBundle, comment: ""), effectedParticipantsName)
            } else {
                return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.added", bundle: Language.preferedBundle, comment: ""), participantName, effectedParticipantsName)
            }
        default:
            return nil
        }
    }

    class func makeRequest(model: SendMessageModel, checkLink: Bool = false) -> (message: Message, req: SendTextMessageRequest) {
        let type = modelMessageType(model.textMessage, checkLink)
        let req = SendTextMessageRequest(threadId: model.threadId,
                                         textMessage: model.textMessage,
                                         messageType: type)
        let message = Message(threadId: model.threadId,
                              message: model.textMessage,
                              messageType: type,
                              ownerId: model.meId,
                              time: UInt(Date().millisecondsSince1970),
                              uniqueId: req.uniqueId,
                              conversation: model.conversation)
        return (message, req)
    }

    class private func modelMessageType(_ textMessage: String, _ checkLink: Bool) ->  ChatModels.MessageType {
        if checkLink {
            return hasLink(textMessage) ? .link : .text
        } else {
            return .text
        }
    }

    class private func hasLink(_ message: String) -> Bool {
        if let linkRegex = NSRegularExpression.urlRegEx {
            let allRange = NSRange(message.startIndex..., in: message)
            return linkRegex.firstMatch(in: message, range: allRange) != nil
        } else {
            return false
        }
    }
}

public extension Array where Element: Message {
    func sortedByTime() -> [Message] {
        sorted(by: {$0.time ?? 0 < $1.time ?? 0})
    }
}
