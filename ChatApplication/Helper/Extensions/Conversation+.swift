//
//  Conversation+.swift
//  ChatApplication
//
//  Created by hamed on 11/17/22.
//

import FanapPodChatSDK
extension Conversation {
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
        pinMessage = newThread.pinMessage
        isArchive = newThread.isArchive
    }

    var isCircleUnreadCount: Bool {
        return unreadCount ?? 0 < 10
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
}
