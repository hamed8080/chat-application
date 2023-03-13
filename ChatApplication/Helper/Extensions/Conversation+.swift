//
//  Conversation+.swift
//  ChatApplication
//
//  Created by hamed on 11/17/22.
//

import FanapPodChatSDK
import Foundation
import SwiftUI

public extension Conversation {
    /// Prevent reconstructing the thread in updates like from a cached version to a server version.
    internal func updateValues(_ newThread: Conversation) {
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

    internal var isCircleUnreadCount: Bool {
        unreadCount ?? 0 < 10
    }

    internal var unreadCountString: String? {
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

    var isLastMessageMine: Bool {
        (lastMessageVO?.ownerId ?? lastMessageVO?.participant?.id) ?? 0 == AppState.shared.user?.id
    }

    var messageStatusIcon: (icon: UIImage, fgColor: Color)? {
        if !isLastMessageMine { return nil }
        if partnerLastSeenMessageId == lastMessageVO?.id {
            return (Message.seenImage!, .orange)
        } else if partnerLastDeliveredMessageId == lastMessageVO?.id ?? 0 {
            return (Message.seenImage!, .gray.opacity(0.7))
        } else if lastMessageVO?.id ?? 0 > partnerLastSeenMessageId ?? 0 {
            return (Message.sentImage!, .gray.opacity(0.7))
        } else { return nil }
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
}
