//
//  Message+.swift
//  ChatApplication
//
//  Created by hamed on 4/15/22.
//

import ChatModels
import ChatCore
import MapKit
import ChatAppModels
import ChatDTO
import ChatExtensions

public extension Message {
    var forwardMessage: ForwardMessage? { self as? ForwardMessage }
    var forwardCount: Int? { forwardMessage?.forwardMessageRequest.messageIds.count }
    var forwardTitle: String? { forwardMessage != nil ? "Forward **\(forwardCount ?? 0)** messages to **\(forwardMessage?.destinationThread.title ?? "")**" : nil }
    var messageTitle: String { message ?? fileMetaData?.file?.originalName ?? forwardTitle ?? "" }
    var markdownTitle: AttributedString {
        let option: AttributedString.MarkdownParsingOptions = .init(allowsExtendedAttributes: false,
                                                                    interpretedSyntax: .inlineOnly,
                                                                    failurePolicy: .throwError,
                                                                    languageCode: nil,
                                                                    appliesSourcePositionAttributes: false)
        guard let attributedString = try? NSMutableAttributedString(markdown: messageTitle, options: option) else { return AttributedString() }
        let title = attributedString.string
        title.matches(char: "@")?.forEach { match in
            let userName = title[Range(match.range, in: title)!]
            let sanitizedUserName = String(userName).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
            attributedString.addAttributes([NSAttributedString.Key.link: NSURL(string: "ShowUser:User?userName=\(sanitizedUserName)")!], range: match.range)
        }
        return AttributedString(attributedString)
    }

    var uploadFile: UploadWithTextMessageProtocol? { self as? UploadWithTextMessageProtocol }
    var fileExtension: String? { uploadFile?.uploadFileRequest?.fileExtension ?? uploadFile?.uploadImageRequest?.fileExtension }
    var fileName: String? { uploadFile?.uploadFileRequest?.fileName ?? uploadFile?.uploadImageRequest?.fileName }
    var type: ChatModels.MessageType? { messageType ?? .unknown }
    var isTextMessageType: Bool { type == .text || isFileType }
    func isMe(currentUserId: Int?) -> Bool { (ownerId ?? 0 == currentUserId ?? 0) || isUnsentMessage || isUploadMessage }
    var isUploadMessage: Bool { self is UploadWithTextMessageProtocol }
    /// Check id because we know that the message was successfully added in server chat.
    var isUnsentMessage: Bool { self is UnSentMessageProtocol && id == nil }

    var isImage: Bool { messageType == .podSpacePicture || messageType == .picture }
    var isAudio: Bool { [MessageType.voice, .podSpaceSound, .sound, .podSpaceVoice].contains(messageType ?? .unknown) }
    var isVideo: Bool { [MessageType.video, .podSpaceVideo, .video].contains(messageType ?? .unknown) }

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
        (fileMetaData?.file?.extension ?? fileExtension ?? "").systemImageNameForFileExtension
    }

    var fileStringName: String {
        switch messageType {
        case .text:
            return "text"
        case .voice:
            return "voice"
        case .picture:
            return "picture"
        case .video:
            return "video"
        case .sound:
            return "sound"
        case .file:
            return "file"
        case .podSpacePicture:
            return "picture"
        case .podSpaceVideo:
            return "video"
        case .podSpaceSound:
            return "sound"
        case .podSpaceVoice:
            return "voice"
        case .podSpaceFile:
            return "file"
        case .link:
            return "link"
        case .endCall:
            return "end_call"
        case .startCall:
            return "start_call"
        case .sticker:
            return "sticker"
        case .location:
            return "location"
        case .participantJoin:
            return "join"
        case .participantLeft:
            return "left"
        case .none:
            return "file"
        case .some(.unknown):
            return "file"
        }
    }

    var isFileType: Bool {
        let fileTypes: [ChatModels.MessageType] = [.voice, .picture, .video, .sound, .file, .podSpaceFile, .podSpacePicture, .podSpaceSound, .podSpaceVoice, .podSpaceVideo]
        return fileTypes.contains(messageType ?? .unknown)
    }

    var coordinate: Coordinate? {
        guard let data = systemMetadata?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Coordinate.self, from: data)
    }

    var appleMapsURL: URL? {
        guard let coordinate = coordinate else { return nil }
        return URL(string: "maps://?q=\(message ?? "")&ll=\(coordinate.lat),\(coordinate.lng)")
    }

    var addressDetail: String? {
        get async {
            typealias AddressContinuation = CheckedContinuation<String?, Never>
            return await withCheckedContinuation { (continuation: AddressContinuation) in
                if let coordinate = coordinate {
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.lat, longitude: coordinate.lng), preferredLocale: .current) { placeMarks, _ in
                        if let place = placeMarks?.first?.postalAddress {
                            let addressDetail = "\(place.country) - \(place.city) - \(place.state) - \(place.street)"
                            continuation.resume(returning: addressDetail)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    var addOrRemoveParticipantString: String {
        let effectedName = addRemoveParticipant?.participnats?.first?.name ?? ""
        let participantName = participant?.name ?? ""
        guard let requestType = addRemoveParticipant?.requestTypeEnum else { return "" }
        switch requestType {
        case .leaveThread:
            return "\(participantName) has left the group"
        case .joinThread:
            return "\(participantName) has joind the group"
        case .removedFromThread:
            return "\(effectedName) remvoed by \(participantName)"
        case .addParticipant:
            return "\(effectedName) added by \(participantName)"
        default:
            return ""
        }
    }
}
