//
//  Conversation+.swift
//  ChatApplication
//
//  Created by hamed on 11/17/22.
//

import ChatModels
import Foundation

public extension Conversation {
    /// Prevent reconstructing the thread in updates like from a cached version to a server version.
    func updateValues(_ newThread: Conversation) {
        admin = newThread.admin
        canEditInfo = newThread.canEditInfo
        canSpam = newThread.canSpam
        closedThread = newThread.closedThread
        description = newThread.description
        group = newThread.group
        id = newThread.id
        image = newThread.image
        joinDate = newThread.joinDate
        lastMessage = newThread.lastMessage
        lastParticipantImage = newThread.lastParticipantImage
        lastParticipantName = newThread.lastParticipantName
        lastSeenMessageId = newThread.lastSeenMessageId
        lastSeenMessageNanos = newThread.lastSeenMessageNanos
        lastSeenMessageTime = newThread.lastSeenMessageTime
        mentioned = newThread.mentioned
        metadata = newThread.metadata
        mute = newThread.mute
        participantCount = newThread.participantCount
        partner = newThread.partner
        partnerLastDeliveredMessageId = newThread.partnerLastDeliveredMessageId
        partnerLastDeliveredMessageNanos = newThread.partnerLastDeliveredMessageNanos
        partnerLastDeliveredMessageTime = newThread.partnerLastDeliveredMessageTime
        partnerLastSeenMessageId = newThread.partnerLastSeenMessageId
        partnerLastSeenMessageNanos = newThread.partnerLastSeenMessageNanos
        partnerLastSeenMessageTime = newThread.partnerLastSeenMessageTime
        pin = newThread.pin
        time = newThread.time
        title = newThread.title
        type = newThread.type
        unreadCount = newThread.unreadCount
        uniqueName = newThread.uniqueName
        userGroupHash = newThread.userGroupHash
        inviter = newThread.inviter
        lastMessageVO = newThread.lastMessageVO
        participants = newThread.participants
        pinMessages = newThread.pinMessages
        isArchive = newThread.isArchive
    }

    var isCircleUnreadCount: Bool {
        unreadCount ?? 0 < 10
    }

    var unreadCountString: String? {
        if let unreadCount = unreadCount, unreadCount > 0 {
            let unreadCountString = String(unreadCount)
            let computedString = unreadCount < 1000 ? unreadCountString : "\(unreadCount / 1000)K+"
            return computedString
        } else {
            return nil
        }
    }

    var metaData: FileMetaData? {
        guard let metadata = metadata?.data(using: .utf8),
              let metaData = try? JSONDecoder().decode(FileMetaData.self, from: metadata) else { return nil }
        return metaData
    }

    var computedImageURL: String? { image ?? metaData?.file?.link }

    func isLastMessageMine(currentUserId: Int?) -> Bool {
        (lastMessageVO?.ownerId ?? lastMessageVO?.participant?.id) ?? 0 == currentUserId
    }

    var computedTitle: String {
        if type == .selfThread {
            return String(localized: "self_thread")
        } else {
            return title ?? ""
        }
    }

    var disableSend: Bool {
        if type != .channel {
            return false
        } else if type == .channel, admin == true {
            return false
        } else {
            // The current user is not an admin and the type of thread is channel
            return true
        }
    }

    var isPrivate: Bool { type == .channel || type == .normal || type == .ownerGroup || type == .channelGroup }

    /// Get Public type equivalent of the thread.
    var publicType: ThreadTypes {
        switch type {
        case .channel, .channelGroup:
            return .publicChannel
        case .normal, .ownerGroup:
            return .publicGroup
        default:
            return type ?? .normal
        }
    }

    /// Get Private type equivalent of the thread.
    var privateType: ThreadTypes {
        switch type {
        case .publicChannel:
            return .channel
        case .publicGroup:
            return .normal
        default:
            return type ?? .normal
        }
    }
}
