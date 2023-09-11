//
//  Conversation+.swift
//  TalkExtensions
//
//  Created by hamed on 11/17/22.
//

import ChatModels
import Foundation

public extension Conversation {
    /// Prevent reconstructing the thread in updates like from a cached version to a server version.
    func updateValues(_ newThread: Conversation) {
        admin = newThread.admin ?? admin
        canEditInfo = newThread.canEditInfo ?? newThread.canEditInfo
        canSpam = newThread.canSpam
        closedThread = newThread.closedThread
        description = newThread.description ?? description
        group = newThread.group ?? group
        id = newThread.id ?? id
        image = newThread.image ?? image
        joinDate = newThread.joinDate ?? joinDate
        lastMessage = newThread.lastMessage ?? lastMessage
        lastParticipantImage = newThread.lastParticipantImage ?? lastParticipantImage
        lastParticipantName = newThread.lastParticipantName ?? lastParticipantName
        lastSeenMessageId = newThread.lastSeenMessageId ?? lastSeenMessageId
        lastSeenMessageNanos = newThread.lastSeenMessageNanos ?? lastSeenMessageNanos
        lastSeenMessageTime = newThread.lastSeenMessageTime ?? lastSeenMessageTime
        mentioned = newThread.mentioned ?? mentioned
        metadata = newThread.metadata ?? metadata
        mute = newThread.mute ?? mute
        participantCount = newThread.participantCount ?? participantCount
        partner = newThread.partner ?? partner
        partnerLastDeliveredMessageId = newThread.partnerLastDeliveredMessageId ?? partnerLastDeliveredMessageId
        partnerLastDeliveredMessageNanos = newThread.partnerLastDeliveredMessageNanos ?? partnerLastDeliveredMessageNanos
        partnerLastDeliveredMessageTime = newThread.partnerLastDeliveredMessageTime ?? partnerLastDeliveredMessageTime
        partnerLastSeenMessageId = newThread.partnerLastSeenMessageId ?? partnerLastSeenMessageId
        partnerLastSeenMessageNanos = newThread.partnerLastSeenMessageNanos ?? partnerLastSeenMessageNanos
        partnerLastSeenMessageTime = newThread.partnerLastSeenMessageTime ?? partnerLastSeenMessageTime
        pin = newThread.pin ?? pin
        time = newThread.time ?? time
        title = newThread.title ?? title
        type = newThread.type ?? type
        unreadCount = newThread.unreadCount ?? unreadCount
        uniqueName = newThread.uniqueName ?? uniqueName
        userGroupHash = newThread.userGroupHash ?? userGroupHash
        inviter = newThread.inviter ?? inviter
        lastMessageVO = newThread.lastMessageVO ?? lastMessageVO
        participants = newThread.participants ?? participants
        pinMessage = newThread.pinMessage ?? pinMessage
        isArchive = newThread.isArchive ?? isArchive
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
        return title ?? ""
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
