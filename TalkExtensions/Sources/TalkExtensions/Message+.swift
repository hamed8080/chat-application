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
    var forwardMessage: ForwardMessage? { self as? ForwardMessage }
    var forwardCount: Int? { forwardMessage?.forwardMessageRequest.messageIds.count }
    var messageTitle: String { message ?? "" }
    var isPublicLink: Bool { message?.contains(AppRoutes.joinLink) == true }
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
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "primary") ?? .blue], range: match.range)
        }
        return AttributedString(attributedString)
    }

    var uploadFile: UploadWithTextMessageProtocol? { self as? UploadWithTextMessageProtocol }
    var fileExtension: String? { uploadFile?.uploadFileRequest?.fileExtension ?? uploadFile?.uploadImageRequest?.fileExtension }
    var fileName: String? { uploadFile?.uploadFileRequest?.fileName ?? uploadFile?.uploadImageRequest?.fileName }
    var type: ChatModels.MessageType? { messageType ?? .unknown }
    var isTextMessageType: Bool { type == .text || type == .link || isFileType }
    func isMe(currentUserId: Int?) -> Bool { (ownerId ?? 0 == currentUserId ?? 0) || isUnsentMessage || isUploadMessage }
    /// We should check metadata to be nil. If it has a value, it means that the message file has been successfully uploaded and sent to the chat server.
    var isUploadMessage: Bool { self is UploadWithTextMessageProtocol && metadata == nil }
    /// Check id because we know that the message was successfully added in server chat.
    var isUnsentMessage: Bool { self is UnSentMessageProtocol && id == nil }

    var isImage: Bool { messageType == .podSpacePicture || messageType == .picture }
    var isAudio: Bool { [MessageType.voice, .podSpaceSound, .sound, .podSpaceVoice].contains(messageType ?? .unknown) }
    var isVideo: Bool { [MessageType.video, .podSpaceVideo, .video].contains(messageType ?? .unknown) }
    var reactionableType: Bool { ![MessageType.endCall, .endCall, .participantJoin, .participantLeft].contains(type) }

    var hardLink: URL? {
        guard
            let name = fileMetaData?.name,
            let link = fileMetaData?.file?.link,
            let ext = fileMetaData?.file?.extension,
            let url = URL(string: link),
            let diskURL = ChatManager.activeInstance?.file.filePath(url)
        else { return nil }
        let hardLink = diskURL.appendingPathComponent(name).appendingPathExtension(ext)
        try? FileManager.default.linkItem(at: diskURL, to: hardLink)
        return hardLink
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

    var fileExtIcon: String {
        (fileMetaData?.file?.extension ?? fileExtension ?? "").systemImageNameForFileExtension
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

    static let textDirectionMark = Language.isRTL ? "\u{200f}" : "\u{200e}"

    var addOrRemoveParticipantString: String? {
        let effectedName = addRemoveParticipant?.participnats?.first?.name ?? ""
        let participantName = participant?.name ?? ""
        guard let requestType = addRemoveParticipant?.requestTypeEnum else { return nil }
        switch requestType {
        case .leaveThread:
            return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.left", comment: ""), participantName)
        case .joinThread:
            return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.joined", comment: ""), participantName)
        case .removedFromThread:
            return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.removed", comment: ""), participantName, effectedName)
        case .addParticipant:
            return Message.textDirectionMark + String(format: NSLocalizedString("Message.Participant.added", comment: ""), participantName, effectedName)
        default:
            return nil
        }
    }
}
