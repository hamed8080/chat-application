//
//  ThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ThreadRow: View {
    
    private (set) var thread:Conversation
    
    init(thread: Conversation) {
        self.thread = thread
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16, content: {
            Avatar(url:thread.image ,userName: thread.inviter?.firstName)
            Text(thread.title ?? "")
        })
    }
}

struct ThreadRow_Previews: PreviewProvider {
    static var thread:Conversation{
        let thread = Conversation(admin: false, canEditInfo: true, canSpam: true, closedThread: false, description: "des", group: true, id: 123, image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png", joinDate: nil, lastMessage: nil, lastParticipantImage: nil, lastParticipantName: nil, lastSeenMessageId: nil, lastSeenMessageNanos: nil, lastSeenMessageTime: nil, mentioned: nil, metadata: nil, mute: nil, participantCount: nil, partner: nil, partnerLastDeliveredMessageId: nil, partnerLastDeliveredMessageNanos: nil, partnerLastDeliveredMessageTime: nil, partnerLastSeenMessageId: nil, partnerLastSeenMessageNanos: nil, partnerLastSeenMessageTime: nil, pin: nil, time: nil, title: "Hamed Hosseini", type: nil, unreadCount: nil, uniqueName: nil, userGroupHash: nil, inviter: nil, lastMessageVO: nil, participants: nil, pinMessage: nil)
        return thread
    }
    
    static var previews: some View {
        ThreadRow(thread: thread)
    }
}
